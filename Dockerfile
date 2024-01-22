FROM alpine:3.19

ARG SCRIPT=scheduler.sh
COPY src/$SCRIPT $SCRIPT

RUN apk add --no-cache --update dos2unix && \
    dos2unix $SCRIPT && \
    apk del dos2unix && \
    chmod +x $SCRIPT
CMD ["./scheduler.sh"]