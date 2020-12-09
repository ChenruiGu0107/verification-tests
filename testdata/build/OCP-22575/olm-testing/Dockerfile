FROM quay.io/openshifttest/alpine as munger
ARG new_image_name
COPY manifests manifests
FROM quay.io/openshift/origin-operator-registry:latest
COPY --from=munger manifests manifests
RUN initializer
