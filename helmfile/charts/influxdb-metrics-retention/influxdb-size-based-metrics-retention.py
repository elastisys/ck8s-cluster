import logging
import requests
import json
from pandas.io.json import json_normalize
import os
import urllib.parse

def create_logger():
    global logger
    logger = logging.getLogger('influxdb_size_based_metrics_retention')
    LOGLEVEL = os.environ.get('LOGLEVEL', 'WARNING').upper()
    logger.setLevel(LOGLEVEL)
    ch = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s \n%(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

def get_config():
    global INFLUXDB_HOST
    global INFLUXDB_PORT
    global INFLUXDB_USER
    global INFLUXDB_PASSWORD
    global INFLUXDB_DATABASE
    global INFLUXDB_DATABASE_SIZE_LIMIT_STRING
    global INFLUXDB_MIN_SHARDS_STRING
    global PROMETHEUS_HOST
    global PROMETHEUS_PORT
    global PROMETHEUS_INFLUXDB_METRIC

    # get configuration from environment variables
    try:
        INFLUXDB_HOST = os.environ['INFLUXDB_HOST']
        INFLUXDB_PORT = os.environ['INFLUXDB_PORT']
        INFLUXDB_USER = os.environ['INFLUXDB_USER']
        INFLUXDB_PASSWORD = os.environ['INFLUXDB_PASSWORD']
        INFLUXDB_DATABASE = os.environ['INFLUXDB_DATABASE']
        INFLUXDB_DATABASE_SIZE_LIMIT_STRING = os.environ['INFLUXDB_DATABASE_SIZE_LIMIT']
        INFLUXDB_MIN_SHARDS_STRING = os.environ['INFLUXDB_MIN_SHARDS']
        PROMETHEUS_HOST = os.environ['PROMETHEUS_HOST']
        PROMETHEUS_PORT = os.environ['PROMETHEUS_PORT']
        PROMETHEUS_INFLUXDB_METRIC = os.environ['PROMETHEUS_INFLUXDB_METRIC']
    except KeyError as err:
        logger.error("Environment variable [%s] is not set!", str(err))
        quit()

def parse_numeric_config():
    global INFLUXDB_DATABASE_SIZE_LIMIT
    global INFLUXDB_MIN_SHARDS

    try:
        INFLUXDB_DATABASE_SIZE_LIMIT = int(INFLUXDB_DATABASE_SIZE_LIMIT_STRING)
        INFLUXDB_MIN_SHARDS = int(INFLUXDB_MIN_SHARDS_STRING)
    except ValueError as err:
        logger.error("Environment variable [%s] could not be parsed to integer!", str(err))
        quit()

def get_db_size():
    # create request url to query Prometheus regarding the InfluxDB database size
    PROMETHEUS_GET_URL = "http://" + PROMETHEUS_HOST + ":" + PROMETHEUS_PORT + "/api/v1/query?query=" + PROMETHEUS_INFLUXDB_METRIC

    # send the request to Prometheus
    try:
        prometheus_response = requests.get(url = PROMETHEUS_GET_URL)
    except:
        logger.error("Connection to [%s] failed", PROMETHEUS_GET_URL)
        quit()

    # parse the response from Prometheus
    try:
        prometheus_query_response_data = prometheus_response.json()
        prometheus_query_response_data_normalized = json_normalize(data=prometheus_query_response_data['data']['result'], errors='ignore')
        prometheus_query_response_data_filtered = prometheus_query_response_data_normalized[prometheus_query_response_data_normalized['metric.__name__']==PROMETHEUS_INFLUXDB_METRIC]
        prometheus_metric_row = prometheus_query_response_data_filtered.iloc[0]
        prometheus_metric_value = prometheus_metric_row['value'][1]
        db_size = int(prometheus_metric_value)
        return db_size
    except:
        logger.error("Could not get the current size of [%s] database.", INFLUXDB_DATABASE)
        logger.debug("Response=[%s]", prometheus_response.content)
        quit()

def get_oldest_shard():
    # create request url to query InfluxDB regarding the shards
    INFLUXDB_GET_URL = "http://" + INFLUXDB_HOST + ":" + INFLUXDB_PORT + "/query?u=" + INFLUXDB_USER + "&p=" + INFLUXDB_PASSWORD + "&q=SHOW SHARDS"
        
    try:
        influxdb_get_response = requests.get(url = INFLUXDB_GET_URL)
    except:
        logger.error("Connection to [%s] failed", INFLUXDB_GET_URL)
        quit()

    try:
        data = influxdb_get_response.json()
        # normalized = json_normalize(data=data['results'][0]['series'], record_path='values', meta=data['results'][0]['series'][0]['columns'], errors='ignore')

        normalized = json_normalize(data=data['results'][0]['series'], record_path='values', errors='ignore')
        normalized.columns = ['id', 'database', 'retention_policy', 'shard_group', 'start_time', 'end_time', 'expiry_time', 'owners'] 

        #TODO: get column names from the JSON file instead the hardcoded list above
        #colnames = json_normalize(data=data['results'][0]['series'][0], record_path='columns')
        # normalized.columns = colnames.values

        logger.debug("\nNORMALIZED")
        logger.debug(normalized)

        fitered_data = normalized[normalized['database']==INFLUXDB_DATABASE]

        logger.debug("\nFILTERED")
        logger.debug(fitered_data)

        filtered_rows_count = fitered_data.shape[0]

        logger.debug("\nFILTERED ROWS COUNT: %d", filtered_rows_count)

        if (filtered_rows_count <= INFLUXDB_MIN_SHARDS):
            logger.warning("[%s] database consists only of [%d] shards. Removing oldest shard aborted!", INFLUXDB_DATABASE, INFLUXDB_MIN_SHARDS)
            quit()

        sorted_data = fitered_data.sort_values(by=['expiry_time'])

        logger.debug("\nSORTED")
        logger.debug(sorted_data)

        oldest_expiry_row = sorted_data.iloc[0]

        logger.debug("\nOLDEST")
        logger.debug(oldest_expiry_row)

        oldest_expiry_shard_id = oldest_expiry_row['id']
        oldest_expiry_database = oldest_expiry_row['database']
        oldest_expiry_retention_policy = oldest_expiry_row['retention_policy']
        oldest_expiry_time = oldest_expiry_row['expiry_time']

        logger.debug("\nVALUES")
        logger.debug("oldest_expiry_shard_id: %s", str(oldest_expiry_shard_id))
        logger.debug("oldest_expiry_database: %s", str(oldest_expiry_database))
        logger.debug("oldest_expiry_retention_policy: %s", str(oldest_expiry_retention_policy))
        logger.debug("oldest_expiry_time: %s", str(oldest_expiry_time))

        return oldest_expiry_shard_id
    except:
        logger.error("Could not get the oldes shard of [%s] database.", INFLUXDB_DATABASE)
        logger.debug("Response=[%s]", str(influxdb_get_response.content))
        quit()

def drop_shard(shard_id):
    query = "DROP SHARD " + str(shard_id)
    INFLUXDB_QUERY = urllib.parse.quote(query)

    INFLUXDB_DROP_URL = "http://" + INFLUXDB_HOST + ":" + INFLUXDB_PORT + "/query?u=" + INFLUXDB_USER + "&p=" + INFLUXDB_PASSWORD + "&q=" + INFLUXDB_QUERY
    logger.debug("\nPOST URL: " + INFLUXDB_DROP_URL)

    # try:
    #     influxdb_drop_response = requests.post(url = INFLUXDB_DROP_URL)
    # except:
    #     logger.error("Connection to [%s] failed", INFLUXDB_DROP_URL)
    #     quit()
    
    # logger.debug(influxdb_drop_response)
    logger.info("Shard with id [%d] dropped successfully.", shard_id)

def main():
    create_logger()
    get_config()
    parse_numeric_config()

    db_size = get_db_size()

    if db_size <= INFLUXDB_DATABASE_SIZE_LIMIT:
        logger.info("Current size of [%s] database [%d] is within the limit [%d]. No action needed.", INFLUXDB_DATABASE, db_size, INFLUXDB_DATABASE_SIZE_LIMIT)
        quit()

    logger.warning("Current size of [%s] database [%d] is over the limit [%d]! Removing the oldest shard.", INFLUXDB_DATABASE, db_size, INFLUXDB_DATABASE_SIZE_LIMIT)

    oldest_shard_id = get_oldest_shard()
    drop_shard(oldest_shard_id)

if __name__ == "__main__":
    main()