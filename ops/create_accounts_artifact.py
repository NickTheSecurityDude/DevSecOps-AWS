import boto3,sys,json

# TODO: add paginators, validate account numbers

# Get result type for env variable, valid types, single account/comma separated accounts,ou id,ALL
targets=sys.argv[1]

org_client = boto3.client('organizations')

accts=[]

if targets[0:3] == 'ou-':
  org_client = boto3.client('organizations')

  response = org_client.list_accounts_for_parent(
    ParentId=targets,
  )

  for i in response['Accounts']:
    accts.append(i['Id'])
elif targets == 'ALL':
  response = org_client.list_accounts()  
  for i in response['Accounts']:
    accts.append(i['Id'])
else:
  for i in targets.split(','):
    accts.append(i)

if len(accts) == 0:
  sys.exit(1)
else:
  # Print and/or Write accounts to artifact file
  accts=json.dumps(accts)
  print(accts)
  #f = open("accounts.txt", "w")
  #f.write(str(accts))
  #f.close()
