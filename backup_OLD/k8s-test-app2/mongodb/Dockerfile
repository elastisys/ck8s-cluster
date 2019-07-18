FROM mongo:4.0
#COPY entrypoint.sh /root/entrypoint.sh
RUN chown -R mongodb:mongodb /var/log /data/db /tmp/
USER mongodb
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mongod"]
