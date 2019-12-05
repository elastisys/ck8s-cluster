# importing the requests library 
import requests
import json
from pandas.io.json import json_normalize
import os
import urllib.parse

def main():
    user = "demo"
    password = "xNRZXQweUzAxxScyteEi"
    host = "localhost"
    port = "8086"

    # ====================== LIMIT PER DATABASE =======================

    database = 'service_cluster'
    # database = 'workload_cluster'

    database_size_limit = 404612
    # database_size_limit = 6237480

    stream = os.popen('kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" exec -n influxdb-prometheus $(kubectl get pods -o name -n influxdb-prometheus | grep -v "backup") -- du -s /var/lib/influxdb/data/' + database + ' | cut -f 1')
    output = stream.read()
    # print(output)

    current_size = int(output)
    # print(current_size)

    if current_size <= database_size_limit:
        print("INFO: Current size of database [" + database + "] is within the limit. No action needed.")
        quit()

    print("WARNING: Current size of database [" + database + "] is over the limit! Removing the oldest shard.")

    # ====================== END OF LIMIT PER DATABASE =======================

    # ====================== SINGLE LIMIT FOR ALL DATABASES =======================

    # size_limit = 1066396

    # stream = os.popen('kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" exec -n influxdb-prometheus $(kubectl get pods -o name -n influxdb-prometheus | grep -v "backup") -- du -s /var/lib/influxdb/data | cut -f 1')
    # output = stream.read()
    # # print(output)

    # current_size = int(output)
    # print(current_size)

    # if current_size <= size_limit:
    #     print("INFO: Current size of all databases is within the limit. No action needed.")
    #     quit()

    # print("WARNING: Current size of all databases is over the limit! Removing the oldest shard.")

    # ====================== END OF SINGLE LIMIT FOR ALL DATABASES =======================

    # quit()

    # api-endpoint
    URL = "http://" + host + ":" + port + "/query?u=" + user + "&p=" + password + "&q=SHOW SHARDS"
        
    # sending get request and saving the response as response object 
    r = requests.get(url = URL)

    data = r.json()
    # normalized = json_normalize(data=data['results'][0]['series'], record_path='values', meta=data['results'][0]['series'][0]['columns'], errors='ignore')

    normalized = json_normalize(data=data['results'][0]['series'], record_path='values', errors='ignore')


    normalized.columns = ['id', 'database', 'retention_policy', 'shard_group', 'start_time', 'end_time', 'expiry_time', 'owners'] 

    #TODO: get column names from the JSON file instead the hardcoded list above
    #colnames = json_normalize(data=data['results'][0]['series'][0], record_path='columns')
    # normalized.columns = colnames.values

    print("\nNORMALIZED")
    print(normalized)

    # fitered_data = normalized[normalized['database']!='_internal'] # SINGLE LIMIT FOR ALL DATABASES
    fitered_data = normalized[normalized['database']==database] # LIMIT PER DATABASE

    print("\nFILTERED")
    print(fitered_data)

    sorted_data = fitered_data.sort_values(by=['expiry_time'])

    print("\nSORTED")
    print(sorted_data)

    oldest_expiry_row = sorted_data.iloc[0]

    print("\nOLDEST")
    print(oldest_expiry_row)

    oldest_expiry_id = oldest_expiry_row['id']
    oldest_expiry_database = oldest_expiry_row['database']
    oldest_expiry_retention_policy = oldest_expiry_row['retention_policy']
    oldest_expiry_time = oldest_expiry_row['expiry_time']

    print("\nVALUES")
    print("oldest_expiry_id:\t" + str(oldest_expiry_id))
    print("oldest_expiry_database:\t" + str(oldest_expiry_database))
    print("oldest_expiry_retention_policy:\t" + str(oldest_expiry_retention_policy))
    print("oldest_expiry_time:\t" + str(oldest_expiry_time))

    query = "DROP SHARD " + str(oldest_expiry_id)
    parsed_query = urllib.parse.quote(query)

    POST_URL = "http://" + host + ":" + port + "/query?u=" + user + "&p=" + password + "&q=" + parsed_query
    print("\nPOST URL")
    print(POST_URL)
    # r = requests.post(url = POST_URL)
    # print(r)

if __name__ == "__main__":
    main()