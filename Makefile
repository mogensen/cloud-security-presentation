KIND_CLUSTER_NAME="goto-cluster"

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

kind-create: ## Create local kubernetes cluster
	kind create cluster --config=./kind-cluster-config.yaml --name $(KIND_CLUSTER_NAME)
	kubectl apply --wait -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml

kind-delete: ## Delete local kubernetes cluster
	kind delete cluster --name $(KIND_CLUSTER_NAME)
