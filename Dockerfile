FROM debian:buster-slim
LABEL maintainer="Coding <code@ongoing.today>"

## Install tools and libraries
RUN apt update -yqq && \
    mkdir -p /usr/share/man/man1 && \
    mkdir -p /usr/share/man/man7 && \
    apt install -yqq --no-install-recommends \
        apache2 \
        ca-certificates \
        git \
        php \
        libapache2-mod-php \
        php-cli \
        php-curl \
        php-gd \
        php-intl \
        php-json \
        php-pgsql \
        php-mbstring \
        php-opcache \
        php-xml \
        postgresql-client \
        supervisor && \
# Fix the Breakage from the AddTrust External CA Root Expiration
# https://www.agwa.name/blog/post/fixing_the_addtrust_root_expiration
    sed -i -E 's#^mozilla/AddTrust_External_Root.crt#\!mozilla/AddTrust_External_Root.crt#' /etc/ca-certificates.conf && \
    update-ca-certificates && \
# Checkout TT-RSS and plugins
    git clone https://git.tt-rss.org/fox/tt-rss.git /var/www/html/ttrss && \
# Clean up
    rm -rf /var/www/html/ttrss/.git && \
    apt remove -y git && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /usr/share/doc /usr/local/share/man /var/cache/debconf/*-old && \
    rm -rf /usr/share/man

# Copy files to docker
COPY ttrss.conf /etc/apache2/sites-available/ttrss.conf
COPY config.php /var/www/html/ttrss/config.php
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

# Configure Apache
RUN chmod 644 /etc/apache2/sites-available/ttrss.conf && \
    a2ensite ttrss.conf && \
    a2dissite 000-default && \
    a2dissite default-ssl && \
    chmod +x /entrypoint.sh && \
    chown -R www-data:www-data /var/www/html/ttrss

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
