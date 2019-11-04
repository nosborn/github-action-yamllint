FROM python:3-alpine

ENV PYTHON_UNBUFFERED 1

RUN python3 -m pip install --no-cache-dir yamllint==1.18.* \
  && apk --update --no-cache add curl=~7.66 jq=~1.6

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
