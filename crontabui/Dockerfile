FROM alseambusher/crontab-ui AS original_image
RUN ls /

FROM library/docker:stable

COPY --from=original_image /crontab-ui /crontab-ui
WORKDIR /crontab-ui

RUN apk --no-cache add \
    wget \
    curl \
    nodejs \
    npm \
    supervisor \
    tzdata

RUN sed -i 's/^var base_url.*/var base_url = process.env.BASE_URL/' routes.js

ENV CRON_PATH /etc/crontabs
COPY supervisord.conf /etc/supervisord.conf

ENV HOST=0.0.0.0
ENV CRON_IN_DOCKER true
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
