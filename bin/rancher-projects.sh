#!/bin/bash

#set -x

usage() {
    echo "Usage: $0"
    echo "  --cluster-name              Cluster name                                 Example: rke2-dev"
    echo "  --project-name              Project name                                 Example: MyProject"
    echo "  --create-project            Creates project if it doesn't exist"
    echo "  --namespace                 Namespace)                                   Example: my-namespace"
    echo "  --create-namespace          Creates namespace if it doesn't exist"
    echo "  --rancher-server            Rancher server                               Example: https://rancher.dev.local"
    echo "  --rancher-access-key        Rancher Access Key                           Example: token-abcdef" 
    echo "  --rancher-secret-key        Rancher Secret Key                           Example: abcdefghijklmnopqrstuvwxyz"
    echo "  --create-kubeconfig         Generates kubeconfig file for the cluster"
    echo "  --get-clusters-by-type      Returns a list of clusters by type           Example: rke2"
    echo "  --get-clusters-by-label     Returns a list of clusters by label          Example: rke2-upgrade=true,maintenance=true"
    echo "  --kubeconfig                Overrides the kubeconfig file name           Default: rancher-projects-kubeconfig"
    echo "  --kubeconfig-dir            Overrides the kubeconfig file directory      Default: Current directory"
    echo "  --kubeconfig-prefix         Overrides the kubeconfig file prefix         Default: <blank>"
    exit 1; }

CREATE_PROJECT="false"
CREATE_NAMESPACE="false"
CREATE_KUBECONFIG="false"
KUBECONFIG_FILE="rancher-projects-kubeconfig"

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
case $1 in
    -c|--cluster-name)
    CLUSTER_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--project-name)
    PROJECT_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    --create-project)
    CREATE_PROJECT="true"
    shift # past argument
    ;;
    -n|--namespace)
    NAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    --create-namespace)
    CREATE_NAMESPACE="true"
    shift # past argument
    ;;
    -s|--rancher-server)
    CATTLE_SERVER="$2"
    shift # past argument
    shift # past value
    ;;
    -A|--rancher-access-key)
    CATTLE_ACCESS_KEY="$2"
    shift # past argument
    shift # past value
    ;;
    -S|--rancher-secret-key)
    CATTLE_SECRET_KEY="$2"
    shift # past argument
    shift # past value
    ;;
    --create-kubeconfig)
    CREATE_KUBECONFIG="true"
    shift # past argument
    ;;
    --get-clusters-by-type)
    CLUSTER_TYPE="$2"
    shift # past argument
    shift # past value
    ;;
    --get-clusters-by-label)
    CLUSTER_LABELS="$2"
    shift # past argument
    shift # past value
    ;;
    --kubeconfig)
    KUBECONFIG="$2"
    shift # past argument
    shift # past value
    ;;
    --kubeconfig-dir)
    KUBECONFIG_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    --kubeconfig-prefix)
    KUBECONFIG_PREFIX="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--debug)
    DEBUG="true"
    shift # past argument
    ;;
    -h|--help)
    usage
    shift # past argument
    ;;
    -*|--*)
    echo "Unknown option $1"
    exit 1
    ;;
    *)
    POSITIONAL_ARGS+=("$1") # save positional arg
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ "${DEBUG}" == "true" ];
then
    echo "Enabling debug logging"
    set -x
fi

verify-command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "$1 is not installed. Please install $1 and try again."
        exit 1
    fi
}

verify-tools() {
    echo "Verifying tools..."
    verify-command() {
        if ! command -v "$1" >/dev/null 2>&1; then
            echo "$1 is not installed. Please install $1 and try again."
            exit 1
        fi
    }

    verify-command jq
    verify-command curl
}

verify_settings() {
    echo "Verifying settings..."

    if [ -z "${KUBECONFIG}" ]; then
        if [ "${DEBUG}" == "true" ]; then
            echo "Using Kubeconfig DIR"
        fi
        if [ -z "${KUBECONFIG_DIR}" ]; then
            KUBECONFIG_DIR="$(pwd)"
            if [ "${DEBUG}" == "true" ]; then
                echo "Defaulting to pwd"
            fi
        else
            if [ "${DEBUG}" == "true" ]; then
                echo "Making Kubeconfig DIR"
            fi
            mkdir -p "${KUBECONFIG_DIR}"
            if [ ! -d "${KUBECONFIG_DIR}" ]; then
                echo "Kubeconfig directory does not exist. Please create it and try again."
                exit 1
            fi
        fi
    fi

    required_vars=("CLUSTER_NAME" "CLUSTER_TYPE" "CLUSTER_LABELS" "CATTLE_SERVER" "CATTLE_ACCESS_KEY" "CATTLE_SECRET_KEY")

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "${var} is required. Please specify it and try again."
            exit 1
        fi
    done

    if [ "${DEBUG}" == "true" ]; then
        set -x
        echo "Dumping options"
        for var in "CLUSTER_NAME" "PROJECT_NAME" "CREATE_PROJECT" "NAMESPACE" "CREATE_NAMESPACE" "CATTLE_SERVER" "CATTLE_ACCESS_KEY" "CATTLE_SECRET_KEY" "CREATE_KUBECONFIG" "CLUSTER_TYPE" "CLUSTER_LABELS" "KUBECONFIG" "KUBECONFIG_DIR" "KUBECONFIG_PREFIX" "DEBUG"; do
            echo "${var}: ${!var}"
        done
    fi
}

verify_access() {
    echo "Verifying access to Rancher server..."
    output=$(curl -H 'content-type: application/json' -k -s -o /dev/null -w "%{http_code}" "${CATTLE_SERVER}/v3/" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}")
    if [ "${output}" -ne 200 ]; then
        echo "Failed to authenticate to ${CATTLE_SERVER}"
        exit 2
    fi
    echo "Successfully authenticated to ${CATTLE_SERVER}"
}

verify-cluster() {
    echo "Verifying cluster ${CLUSTER_NAME}..."
    output=$(curl -H 'content-type: application/json' -k -s -o /dev/null -w "%{http_code}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" "${CATTLE_SERVER}/v3/clusters?name=${CLUSTER_NAME}")
    if [ "${output}" -ne 200 ]; then
        echo "Failed to find cluster ${CLUSTER_NAME}"
        exit 2
    fi
    echo "Successfully found cluster ${CLUSTER_NAME}"
}

get-cluster-status() {
    cluster_name=$1
    echo "Verifying cluster ${cluster_name}..."
    CLUSTER_STATUS=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/clusters?name=${cluster_name}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].state')
    echo "Cluster status: ${CLUSTER_STATUS}"
}

verify-project() {
    echo "Verifying project ${PROJECT_NAME}..."
    PROJECT_DATA=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/projects?name=${PROJECT_NAME}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0]')
    if [[ "${PROJECT_DATA}" == "null" ]]; then
        echo "Failed to find project ${PROJECT_NAME}"
        exit 2
    fi
    echo "Successfully found project ${PROJECT_NAME}"
}

create-project() {
    echo "Checking if project ${PROJECT_NAME} exists..."
    PROJECT_DATA=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/projects?clusterId=${CLUSTER_ID}&name=${PROJECT_NAME}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0]')
    if [[ "${PROJECT_DATA}" == "null" ]]; then
        echo "Creating project ${PROJECT_NAME}..."
        curl -X POST -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/projects" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -d "{\"type\":\"project\", \"name\":\"${PROJECT_NAME}\", \"clusterId\":\"${CLUSTER_ID}\"}" > /dev/null
        if [ $? -ne 0 ]; then
            echo "Failed to create project ${PROJECT_NAME}"
            exit 2
        fi
        echo "Successfully created project ${PROJECT_NAME}"
    else
        echo "Project ${PROJECT_NAME} already exists"
    fi
}

verify-namespace() {
    echo "Verifying namespace ${NAMESPACE}..."
    if curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/k8s/clusters/${CLUSTER_ID}/v1/namespaces/${NAMESPACE}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq .code | tr -d '"' | grep -q 'NotFound'; then
        echo "Could not find namespace ${NAMESPACE}"
        return 1
    fi
    echo "Successfully found namespace ${NAMESPACE}"
    return 0
}

create-namespace() {
    echo "Checking if namespace ${NAMESPACE} exists..."
    if ! verify-namespace; then
        echo "Creating namespace ${NAMESPACE}..."
        curl -X POST -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/k8s/clusters/${CLUSTER_ID}/v1/namespaces" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -d "{\"type\":\"namespace\", \"metadata\": {\"name\":\"${NAMESPACE}\"}}" > /dev/null
        echo "Successfully created namespace ${NAMESPACE}"
        echo "Sleeping for 5 seconds to allow namespace to settle..."
        sleep 5
    else
        echo "Namespace ${NAMESPACE} already exists"
    fi
}

get-all-cluster-ids() {
    echo "Getting all cluster IDs..."
    CLUSTER_IDS=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/clusters" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[] | .name + ":" + .id')
    echo "Cluster IDs: ${CLUSTER_IDS}"
    if [[ -z $CLUSTER_IDS ]]; then
        echo "Failed to get cluster IDs"
        exit 2
    fi
}

get-cluster-id() {
    echo "Getting cluster ID..."
    CLUSTER_ID=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/clusters?name=${CLUSTER_NAME}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].id')
    if [ $? -ne 0 ]; then
        echo "Failed to get cluster ID"
        exit 2
    fi
    echo "Cluster ID: ${CLUSTER_ID}"
    echo "Successfully got cluster ID"
}

get-cluster-type() {
    local cluster_name=$1
    echo "Getting cluster provider..."
    CLUSTER_PROVIDER=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/clusters?name=${cluster_name}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].provider')
    if [ $? -ne 0 ]; then
        echo "Failed to get cluster provider"
        exit 2
    fi
    echo "Cluster Provider: ${CLUSTER_PROVIDER}"
    echo "Successfully got cluster provider"
}

filter-by-cluster-label() {
    local cluster_name=$1
    local keypair=$2
    echo "Filtering by cluster label"
    echo "Cluster Name: ${cluster_name}"
    echo "Label: ${keypair}"
    key=$(echo "${keypair}" | awk -F '=' '{print $1}')
    value=$(echo "${keypair}" | awk -F '=' '{print $2}')
    LABEL=$(echo "\"$key\": \"${value}\"")
    if curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/clusters?name=${cluster_name}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r ".data[0].labels | has({${LABEL}})" > /dev/null; then
        echo "Label match found"
        found=1
        labelcount=$((labelcount+1))
    else
        echo "Label not found"
    fi
}

get-project-info() {
    echo "Getting project info..."
    PROJECT_ID=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/projects?clusterId=${CLUSTER_ID}&name=${PROJECT_NAME}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.data[0].id')
    if [ $? -ne 0 ]; then
        echo "Failed to get project info"
        exit 2
    fi
    echo "Project ID: ${PROJECT_ID}"
}

assign-namespace-to-project() {
    echo "Assigning namespace ${NAMESPACE} to project ${PROJECT_NAME}..."
    echo "Collecting namespace details..."
    PROJECT=$(echo "${PROJECT_ID}" | awk -F ':' '{print $2}')
    echo "Project long: ${PROJECT_ID}"
    echo "Project short: ${PROJECT}"
    NAMESPACE_DATA=$(curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/k8s/clusters/${CLUSTER_ID}/v1/namespaces/${NAMESPACE}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq)
    NAMESPACE_POST=$(echo "${NAMESPACE_DATA}" | jq --arg PROJECT_ID "${PROJECT_ID}" '.metadata.annotations."field.cattle.io/projectId" = $PROJECT_ID' | jq --arg PROJECT "${PROJECT}" '.metadata.labels."field.cattle.io/projectId" = $PROJECT')
    echo "Updating namespace..."
    curl -X PUT -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/k8s/clusters/${CLUSTER_ID}/v1/namespaces/${NAMESPACE}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -d "${NAMESPACE_POST}" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Failed to assign namespace ${NAMESPACE} to project ${PROJECT_NAME}"
        exit 2
    fi
    echo "Successfully assigned namespace ${NAMESPACE} to project ${PROJECT_NAME}"
}

verify-project-assignment() {
    echo "Verifying project assignment..."
    if ! curl -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/k8s/clusters/${CLUSTER_ID}/v1/namespaces/${NAMESPACE}" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq .metadata.annotations | grep "field.cattle.io/projectId" | awk '{print $2}' | tr -d '", ' | grep -q "${PROJECT_ID}"; then
        echo "Failed to verify project assignment"
        exit 2
    fi
    echo "Successfully verified project assignment"
}

generate-kubeconfig() {
    echo "Generating kubeconfig..."
    if [ -z "${KUBECONFIG}" ]; then
        KUBECONFIG_FILE=$1
        CLUSTER_ID=$2
    else
        KUBECONFIG_FILE="${KUBECONFIG}"
    fi
    if [ ! -z "${KUBECONFIG_PREFIX}" ]; then
        KUBECONFIG_FILE="${KUBECONFIG_PREFIX}-${KUBECONFIG_FILE}"
    fi
    echo "Kubeconfig file: ${KUBECONFIG_FILE}"
    echo "Cluster ID: ${CLUSTER_ID}"
    curl -X POST -H 'content-type: application/json' -k -s "${CATTLE_SERVER}/v3/clusters/${CLUSTER_ID}?action=generateKubeconfig" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" | jq -r '.config' > "${KUBECONFIG_DIR}/${KUBECONFIG_FILE}"
}

verifyTools() {
    echo "Verifying tools..."

    # Check if required tools are installed
    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required but not installed. Please install curl and try again."
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "jq is required but not installed. Please install jq and try again."
        exit 1
    fi

    # Add more tool verifications if needed

    echo "Tool verification complete."
}

verifySettings() {
    echo "Verifying settings..."

    if [[ -z "${CLUSTER_NAME}" ]]; then
        echo "CLUSTER_NAME is required. Please specify it and try again."
        exit 1
    fi

    # Check for other required settings and perform additional verifications

    echo "Settings verification complete."
}

verifyAccess() {
    echo "Verifying access to Rancher server..."

    # Perform a curl request to the Rancher server to verify access
    response=$(curl -H 'content-type: application/json' -k -s -o /dev/null -w "%{http_code}" "${CATTLE_SERVER}/v3/" -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}")

    if [ "${response}" -ne 200 ]; then
        echo "Failed to authenticate to ${CATTLE_SERVER}"
        exit 2
    fi

    echo "Successfully authenticated to ${CATTLE_SERVER}"
}


if [ -z "${CLUSTER_TYPE}" ] && [ -z "${CLUSTER_LABELS}" ]; then
    verify-cluster
    get-cluster-id

    if [ ! -z "${PROJECT_NAME}" ]; then
        if [ "${CREATE_PROJECT}" == "true" ]; then
            create-project
        fi
        verify-project
        get-project-info

        if [ "${CREATE_NAMESPACE}" == "true" ]; then
            create-namespace
        else
            verify-namespace
        fi

        assign-namespace-to-project
        verify-project-assignment
    fi

    if [ "${CREATE_KUBECONFIG}" == "true" ]; then
        generate-kubeconfig "${KUBECONFIG_FILE}" "${CLUSTER_ID}"
    fi
else
    get-all-cluster-ids
    keypairs=$(echo "${CLUSTER_LABELS}" | sed -e 's/,/\n/g')
    keypaircount=$(echo "${CLUSTER_LABELS}" | sed -e 's/,/\n/g' | wc -l)

    for CLUSTER_ID in ${CLUSTER_IDS}; do
        cluster_name=$(echo "${CLUSTER_ID}" | awk -F ':' '{print $1}')
        cluster_id=$(echo "${CLUSTER_ID}" | awk -F ':' '{print $2}')

        echo "Checking if cluster is Active..."
        get-cluster-status "${cluster_name}"

        if [[ "${CLUSTER_STATUS}" == "active" ]]; then
            echo "Cluster is Active"

            if [ ! -z "${CLUSTER_TYPE}" ]; then
                echo "Checking cluster type..."
                get-cluster-type "${cluster_name}"

                if [[ "${CLUSTER_TYPE}" == "${CLUSTER_PROVIDER}" ]]; then
                    echo "Cluster type match found"
                    generate-kubeconfig "${cluster_name}" "${cluster_id}"
                fi
            elif [ ! -z "${CLUSTER_LABELS}" ]; then
                found=0
                foundall=0
                labelcount=0

                for keypair in ${keypairs}; do
                    echo "Checking label ${keypair}"
                    filter-by-cluster-label "${cluster_name}" "${keypair}"
                done

                if [ "${labelcount}" == "${keypaircount}" ]; then
                    echo "Found all labels"
                    foundall=1
                else
                    echo "Label count mismatch"
                    foundall=0
                fi
            else
                found=1
            fi

            if [ "${found}" == "1" ] || [ "${foundall}" == "1" ]; then
                echo "Matching label or no label set"
                generate-kubeconfig "${cluster_name}" "${cluster_id}"
            else
                echo "Skipping cluster due to missing label"
            fi
        else
            echo "Skipping cluster because it is not Active"
        fi

        echo "##################################################################################"
    done
fi
