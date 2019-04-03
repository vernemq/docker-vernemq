## How to release the Helm chart

1. Bump the chart version in [Chart.yaml](Chart.yaml) (`version`) by following semantic versioning from the chart point of view
2. If applicable, bump Docker image version in [values.yaml](values.yaml) (`image.tag`) and [Chart.yaml](Chart.yaml) (`appVersion`)
3. Tag the last commit `helm-X.X.X` where `X.X.X` is the Chart version like in [Chart.yaml](Chart.yaml)
4. Push your changes and the tag, Travis will take care of the rest