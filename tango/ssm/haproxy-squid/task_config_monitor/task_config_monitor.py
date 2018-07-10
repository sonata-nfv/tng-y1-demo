"""
Copyright (c) 2015 SONATA-NFV
ALL RIGHTS RESERVED.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Neither the name of the SONATA-NFV [, ANY ADDITIONAL AFFILIATION]
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

This work has been performed in the framework of the SONATA project,
funded by the European Commission under Grant number 671517 through
the Horizon 2020 and 5G-PPP programmes. The authors would like to
acknowledge the contributions of their colleagues of the SONATA
partner consortium (www.sonata-nfv.eu).
"""

import logging
import yaml
import datetime
from sonsmbase.smbase import sonSMbase

logging.basicConfig(level=logging.INFO)
LOG = logging.getLogger("ssm-task_config-1")
LOG.setLevel(logging.DEBUG)
logging.getLogger("son-mano-base:messaging").setLevel(logging.INFO)


class TaskConfigMonitorSSM(sonSMbase):

    def __init__(self):

        """
        :param specific_manager_type: specifies the type of specific manager that could be either fsm or ssm.
        :param service_name: the name of the service that this specific manager belongs to.
        :param function_name: the name of the function that this specific manager belongs to, will be null in SSM case
        :param specific_manager_name: the actual name of specific manager (e.g., scaling, placement)
        :param id_number: the specific manager id number which is used to distinguish between multiple SSM/FSM
        that are created for the same objective (e.g., scaling with algorithm 1 and 2)
        :param version: version
        :param description: description
        """
        self.specific_manager_type = 'ssm'
        self.service_name = 'haproxy-squid'
        self.specific_manager_name = 'task-config-monitor'
        self.id_number = '1'
        self.version = 'v0.1'
        self.counter = 1
        self.monitor_event_finished = False
        self.vnfs = None
        self.vim_uuid = None
        self.scaling_running = True
        self.ancient_vdu = []
        self.nginx_vnfd = None
        self.description = "Task - Config SSM for the haproxy-squid network service."

        super(self.__class__, self).__init__(specific_manager_type= self.specific_manager_type,
                                             service_name= self.service_name,
                                             specific_manager_name = self.specific_manager_name,
                                             id_number = self.id_number,
                                             version = self.version,
                                             description = self.description)

    def on_registration_ok(self):
        LOG.info("Received registration ok event.")
        self.manoconn.publish(topic='specific.manager.registry.ssm.status', message=yaml.dump(
                                  {'name':self.specific_manager_id,'status': 'UP and Running'}))

        # Subscribe to the topic that the SLM will be sending on
        topic = 'generic.ssm.' + self.sfuuid
        self.manoconn.subscribe(self.received_request, topic)

        # Subscribe to a topic to emulate monitor behavior
        topic = 'emulate.monitoring'
        self.manoconn.subscribe(self.emulate_monitor_event, topic)

        # Subscribe to reset topic
        topic = 'emulate.reset'
        self.manoconn.subscribe(self.reset, topic)

    def received_request(self, ch, method, prop, payload):
        """
        This method is called when the SLM is reaching out
        """
        content = yaml.load(payload)

        # Don't react to self-sent messages
        if prop.app_id == self.specific_manager_id:
            LOG.info("Received self-sent message, ignoring...")
            return

        # Don't react to messages that are not a request
        if 'ssm_type' not in content.keys():
            LOG.info("Received message that is not a request, ignoring...")
            return

        if str(content['ssm_type']) == 'task':
            LOG.info("Received a task request")
            self.task_request(prop.correlation_id, content)
            return

        if str(content['ssm_type']) == 'configure':
            LOG.info("Received a configure request")
            self.configure_request(prop.correlation_id, content)
            return

        if str(content['ssm_type']) == 'monitor':
            LOG.info("Received a monitor request")
            self.monitor_data(prop.correlation_id, content)
            return

        # If the request type field doesn't match any of the above
        LOG.info("type " + str(content['ssm_type']) + " not covered by SSM")

    def task_request(self, corr_id, content):
        """
        This method handles a task request. A task request allows the SSM to
        change the tasks in the workflow of the SLM. For the vCDN, we wan to
        add a configuration phase: first we want to dictate the payload for the
        configration FSMs and then we want to trigger there config_event.
        """

        # Update the received schedule
        schedule = content['schedule']

        # schedule.insert(7, 'vnfs_config')
        # schedule.insert(7, 'configure_ssm')

        response = {'schedule': schedule, 'status': 'COMPLETED'}

        LOG.info("task request responded to: " + str(response))

        # Sending a response
        topic = 'generic.ssm.' + self.sfuuid
        self.manoconn.notify(topic,
                             yaml.dump(response),
                             correlation_id=corr_id)

    def configure_request(self, corr_id, content):
        """
        This method handles a configuration request. If the configuration
        request is made during the instantiation workflow, it means that
        the SSM needs to configure which VNF requires a config_event, and
        what the required payload is.
        """

        if content["workflow"] == 'instantiation':
            msg = "Received a configure request for the instantiation workflow"
            self.configure_instantiation(corr_id, content)

        if content["workflow"] == 'scaling':
            msg = "Received a configure request for the reconfigure workflow"
            self.configure_reconfigure(corr_id, content)

    def configure_instantiation(self, corr_id, content):
        """
        This method creates the configure response for the instantiation
        workflow. It will set the trigger for a config_event for each VNF.
        The payload for the config_event is the generic one provided by the
        SP.
        """

        # Build the list of all the IPs of the different nginx VNFs
        ips = []

        for vnf in content['functions']:
            vnfr = vnf['vnfr']
            vnfd = vnf['vnfd']
            vdu_id = vnfd['virtual_deployment_units'][0]['id']
            ip = ''
            if vnfd['name'] == 'nginx':
                for cp in vnfr['virtual_deployment_units'][0]['vnfc_instance'][0]['connection_points']:
                    if cp['type'] != 'management':
                        ip = cp['interface']['address']
                        break
                if vdu_id not in self.ancient_vdu:
                    ips.append(ip)
                    self.ancient_vdu.append(vdu_id)

        LOG.info(str(self.ancient_vdu))
        LOG.info(str(ips))

        # Create response
        response = {}
        response['vnf'] = []

        for vnf in content['functions']:
            new_entry = {}
            new_entry['id'] = vnf['id']
            if vnf['vnfd']['name'] in ['vth-vnf']:
                new_entry['configure'] = {'trigger': True,
                                          'payload': {'ips': ips}}
            else:
                new_entry['configure'] = {'trigger': False,
                                          'payload': {}}

            response['vnf'].append(new_entry)

        LOG.info("Generated response: " + str(response))

        # Opening up scaling workflow
        self.scaling_running = False
        self.last_scaling = datetime.datetime.now()

        # Sending a response
        topic = 'generic.ssm.' + self.sfuuid
        self.manoconn.notify(topic,
                             yaml.dump(response),
                             correlation_id=corr_id)

    def configure_reconfigure(self, corr_id, content):
        """
        This method creates the configure response for the reconfiguration
        workflow. It will set the trigger for a config_event for each VNF.
        The payload for the config_event is the generic one provided by the
        SP.
        """

        # reconfigure and configuration after instantiation are identical

        self.configure_instantiation(corr_id, content)

    def monitor_data(self, corr_id, content):
        """
        This method will be triggered when monitoring data is received.
        """
        LOG.info("New monitoring event: " + str(content))

        # A message on this topic can contain all the records, if they have
        # changed
        if 'vnfs' in content.keys():
            for vnf in content['vnfs']:
                if vnf['vnfd']['name'] == 'nginx':
                    self.nginx_vnfd = vnf['vnfd']
                    self.vim_uuid = vnf['vnfr']['virtual_deployment_units'][0]['vnfc_instance'][0]['vim_id']

        LOG.info('vnfd: ' + str(self.nginx_vnfd))
        LOG.info('vim_id: ' + str(self.vim_uuid))

        # Check if the aggregated monitoring data implies a scaling event
        if 'alertname' in content.keys():
            LOG.info("New alert received.")
            self.evaluate_monitoring(content)

    def evaluate_monitoring(self, content):

        # TODO: how to decide based on monitoring data whether a scaling
        # event is required

        if not self.scaling_running: 
            time_since_last_event = datetime.datetime.now() - self.last_scaling
            LOG.info("time diff: " + str(time_since_last_event.total_seconds()))
            if time_since_last_event.total_seconds() > 60:
                self.scaling_running = True
                self.push_monitor_event()
        else:
            LOG.info("Scaling still running.")

    def push_monitor_event(self):
        """
        This method sends a message to the SLM to start the reconfigure
        workflow.
        """

        self.counter = self.counter + 1

        LOG.info("Sending scaling trigger to MANO")
        message = {}
        message['workflow'] = 'scale_ns'
        message['service_instance_id'] = self.sfuuid
        message['data'] = {'add_vnf': 'nginx'}
        message['data']['vim_uuid'] = self.vim_uuid
        message['data']['vnfd'] = self.nginx_vnfd

        message['data']['vnfd']['virtual_deployment_units'][0]['id'] = 'vdu0' + str(self.counter)

        payload = yaml.dump(message)

        topic = 'monitor.ssm.' + self.sfuuid
        self.manoconn.notify(topic, payload)

    def emulate_monitor_event(self, ch, method, prop, payload):
        """
        This topic processes an emulated monitor event
        """

        LOG.info("Manual Event should trigger MANO")
        self.push_monitor_event()
        self.monitor_event_finished = True

    def reset(self, ch, method, prop, payload):
        """
        This topic processes an emulated monitor event
        """
        self.scaling_running = False



def main():
    TaskConfigMonitorSSM()

if __name__ == '__main__':
    main()
