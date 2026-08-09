FROM alpine:3.23

ARG SCRIPT=*.sh
COPY src/$SCRIPT .

RUN apk add --no-cache --update dos2unix curl tzdata nano && \
    dos2unix $SCRIPT && \
    apk del dos2unix && \
    chmod +x $SCRIPT
CMD ["./scheduler.sh"]