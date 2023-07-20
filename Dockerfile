FROM alpine:3.18

ARG SCRIPT=scheduler.sh
COPY $SCRIPT $SCRIPT

RUN apk add --no-cache --update dos2unix && \
    dos2unix $SCRIPT && \
    apk del dos2unix
CMD ["./scheduler.sh"]