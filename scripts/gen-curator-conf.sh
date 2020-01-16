cat <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: curator-config
  namespace: elastic-system
  labels:
    app: curator
data:
  action_file.yml: |-
    ---    
    actions:
      1:
        action: delete_indices
        description: "Clean up the oldest log-* indices that exceeds total disk space $OTHER_RETENTION_SIZE GB "
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'other-*'
        - filtertype: space
          disk_space: $OTHER_RETENTION_SIZE
          use_age: True
          source: creation_date
        - filtertype: kibana
          exclude: True
      2:
        action: delete_indices
        description: "Clean up the log-* indices that are older then $OTHER_RETENTION_AGE days"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'other-*'
        - filtertype: age
          source: creation_date
          direction: older
          unit: days
          unit_count: $OTHER_RETENTION_AGE
        - filtertype: kibana
          exclude: True  
      3:
        action: delete_indices
        description: "Clean up the oldest kubecomponents-* indices that exceeds total disk space $KUBECOMPONENTS_RETENTION_SIZE GB"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'kubecomponents-*'
        - filtertype: space
          disk_space: $KUBECOMPONENTS_RETENTION_SIZE
          use_age: True
          source: creation_date
        - filtertype: kibana
          exclude: True
      4:
        action: delete_indices
        description: "Clean up the kubecomponents-* indices that are older then $KUBECOMPONENTS_RETENTION_AGE days"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'kubecomponents-*'
        - filtertype: age
          source: creation_date
          direction: older
          unit: days
          unit_count: $KUBECOMPONENTS_RETENTION_AGE
        - filtertype: kibana
          exclude: True
      5:
        action: delete_indices
        description: "Clean up the oldest kubecomponents-* indices that exceeds total disk space $KUBEAUDIT_RETENTION_SIZE GB"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'kubeaudit-*'
        - filtertype: space
          disk_space: $KUBEAUDIT_RETENTION_SIZE
          use_age: True
          source: creation_date
        - filtertype: kibana
          exclude: True
      6:
        action: delete_indices
        description: "Clean up the kubecomponents-* indices that are older then $KUBEAUDIT_RETENTION_AGE days"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'kubeaudit-*'
        - filtertype: age
          source: creation_date
          direction: older
          unit: days
          unit_count: $KUBEAUDIT_RETENTION_AGE
        - filtertype: kibana
          exclude: True
      7:
        action: delete_indices
        description: "Clean up the oldest kubecomponents-* indices that exceeds total disk space $KUBERNETES_RETENTION_SIZE GB"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'kubernetes-*'
        - filtertype: space
          disk_space: $KUBERNETES_RETENTION_SIZE
          use_age: True
          source: creation_date
        - filtertype: kibana
          exclude: True
      8:
        action: delete_indices
        description: "Clean up the kubecomponents-* indices that are older then $KUBERNETES_RETENTION_AGE days"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'kubernetes-*'
        - filtertype: age
          source: creation_date
          direction: older
          unit: days
          unit_count: $KUBERNETES_RETENTION_AGE
        - filtertype: kibana
          exclude: True
EOF

if [ "$ENABLE_POSTGRESQL" == "true" ]; then
cat <<EOF
      9:
        action: delete_indices
        description: "Clean up the oldest postgresql-* indices that exceeds total disk space $POSTGRESQL_RETENTION_SIZE GB"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'postgresql-*'
        - filtertype: space
          disk_space: $POSTGRESQL_RETENTION_SIZE
          use_age: True
          source: creation_date
        - filtertype: kibana
          exclude: True
      10:
        action: delete_indices
        description: "Clean up the postgresql-* indices that are older then $POSTGRESQL_RETENTION_AGE days"
        options:
          continue_if_exception: False
          ignore_empty_list: True
          allow_ilm_indices: True
        filters:
        # https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html
        - filtertype: pattern
          kind: regex
          value: 'postgresql-*'
        - filtertype: age
          source: creation_date
          direction: older
          unit: days
          unit_count: $POSTGRESQL_RETENTION_AGE
        - filtertype: kibana
          exclude: True
EOF
fi
cat <<EOF

  config.yml: |-
    ---
    client:
      hosts:
        - elasticsearch-es-http
      port: 9200
      use_ssl: True 
      ssl_no_validate: True
      http_auth: elastic:$ELASTIC_USER_SECRET
      timeout: 30
      master_only: False
    logging:
      loglevel: DEBUG
      logformat: default
      # This is the default blacklist
      blacklist: ['elasticsearch', 'urllib3']
EOF