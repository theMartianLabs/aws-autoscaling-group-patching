import os
import time
import boto3
import datetime


def invoke_ssm_document(document_name, instance_profile, subnet_id, ssm_auto_assume_role, security_group_ids, target_asg, source_ami):
    ssm_client = boto3.client('ssm')

    parameters = {
        'InstanceProfile': [instance_profile],
        'AutomationAssumeRole': [ssm_auto_assume_role],
        'SubnetId': [subnet_id],
        'SecurityGroupIds': security_group_ids,
        'TargetASG': [target_asg],
        'SourceAMI': [source_ami]
    }
    print(f"Got the parameters: {parameters}")
    
    try:
        response = ssm_client.start_automation_execution(
            DocumentName = document_name,
            Parameters   = parameters
        )
        print(f"Autoscaling Group Patching is Complete")
        execution_id = response['AutomationExecutionId'] 

        time_stamp = time.time()
        time_stamp_string = datetime.datetime.fromtimestamp(time_stamp).strftime('%m-%d-%Y_%H-%M-%S')   
        
        print(execution_id)
    
        return {
        "statusCode": 200,
        "executionId": execution_id,
        "body": 'Autoscaling Group Patching is Complete',
        "Date": time_stamp_string
        }
        
    except Exception as e:
        print(f" {str(e)}")


def lambda_handler(event, context):
    document_name        = os.environ["document_name"]
    instance_profile     = os.environ["instance_profile"]
    subnet_id            = os.environ["subnet_id"]
    ssm_auto_assume_role = os.environ["ssm_automation_assume_role"]
    security_group_ids   = [os.environ["security_group_ids"]] 
    target_asg           = os.environ["target_asg"]
    source_ami           = os.environ["source_ami"]

    
    execution_id = invoke_ssm_document(document_name, instance_profile, subnet_id, ssm_auto_assume_role, security_group_ids, target_asg, source_ami)
    print(f'Finished SSM automation execution with ID: {execution_id}')