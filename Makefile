include app.Makefile
include crd.Makefile
include gcloud.Makefile
include var.Makefile

TAG ?= 2.0
$(info ---- TAG = $(TAG))

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/nuodb-operator/deployer:$(TAG)
NAME ?= nuodb-operator

APP_PARAMETERS ?= { \
  "APP_INSTANCE_NAME": "$(NAME)", \
  "NAMESPACE": "$(NAMESPACE)", \
  "NUODB_OPERATOR_IMAGE": "gcr.io/nuodb-public/nuodb-operator:2.0.2" \
}

TESTER_IMAGE ?= $(REGISTRY)/nuodb-operator/tester:$(TAG)


app/build:: .build/nuodb-operator/deployer \
            .build/nuodb-operator/nuodb-operator \
            .build/nuodb-operator/tester


.build/nuodb-operator: | .build
	mkdir -p "$@"


.build/nuodb-operator/deployer: deployer/* \
                                manifest/* \
                                schema.yaml \
                                .build/var/APP_DEPLOYER_IMAGE \
                                .build/var/MARKETPLACE_TOOLS_TAG \
                                .build/var/REGISTRY \
                                .build/var/TAG \
                                | .build/nuodb-operator
	$(call print_target, $@)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/nuodb-operator" \
	    --build-arg TAG="$(TAG)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


.build/nuodb-operator/tester: apptest/**/*
	$(call print_target, $@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"


.build/nuodb-operator/nuodb-operator: .build/var/REGISTRY \
                                      .build/var/TAG \
                                      | .build/nuodb-operator
	$(call print_target, $@)
	docker pull gcr.io/nuodb-public/nuodb-operator:latest
	docker tag gcr.io/nuodb-public/nuodb-operator:latest "$(REGISTRY)/nuodb-operator:$(TAG)"
	docker push "$(REGISTRY)/nuodb-operator:$(TAG)"
	@touch "$@"
