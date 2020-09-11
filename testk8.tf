resource "kubectl_manifest" "test" {
    count     = length(data.kubectl_filename_list.manifests.matches)
    yaml_body = file( element( data.kubectl_path_documents.manifests.matches, count.index ) )
}

data "kubectl_path_documents" "manifests" {
    pattern = "./manifests/*.yaml"
    vars = {
        docker_image = "nginx"
    }
}