FROM ckan/ckan-base:2.11

# https://github.com/ckan/ckan-docker/issues/196#issuecomment-2520532935
USER root
RUN mkdir /srv/app/.local && chown ckan /srv/app/.local

# Install Scheming extension (required for DCAT)
RUN pip3 install -e "git+https://github.com/ckan/ckanext-scheming.git#egg=ckanext-scheming"

# Install DCAT extension
RUN pip3 install -e git+https://github.com/ckan/ckanext-dcat.git@v2.1.0#egg=ckanext-dcat && \
    pip3 install -r https://raw.githubusercontent.com/ckan/ckanext-dcat/v2.1.0/requirements.txt

# Install OAuth2 extension
RUN pip3 install -e git+https://github.com/keitaroinc/ckanext-keycloak.git#egg=ckanext-keycloak && \
    pip3 install -r https://raw.githubusercontent.com/keitaroinc/ckanext-keycloak/refs/heads/master/requirements.txt

# Copy custom initialization scripts
COPY --chown=ckan-sys:ckan-sys docker-entrypoint.d/* /docker-entrypoint.d/

# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
COPY --chown=ckan-sys:ckan-sys patches ${APP_DIR}/patches

USER ckan

RUN for d in $APP_DIR/patches/*; do \
        if [ -d $d ]; then \
            for f in `ls $d/*.patch | sort -g`; do \
                cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
            done ; \
        fi ; \
    done
