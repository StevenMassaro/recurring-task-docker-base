FROM alpine:3.22

ARG SCRIPT=*.sh
COPY src/$SCRIPT .

RUN apk add --no-cache --update dos2unix && \
    dos2unix $SCRIPT && \
    apk del dos2unix && \
    chmod +x $SCRIPT
CMD ["./scheduler.sh"]