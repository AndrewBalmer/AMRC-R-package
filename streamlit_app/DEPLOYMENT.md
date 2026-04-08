# Streamlit Deployment

This app is a hybrid Python + R application. The clean deployment path is a
container-based host, not a terminal-only local launch.

## Recommended route

Use a Docker-capable host such as Render.

Why:

- the UI is Streamlit/Python
- the analysis backend runs through `Rscript`
- the app depends on packaged R data and R package installation
- container deployment keeps the runtime consistent with local and CI checks

## Render

This repo now includes:

- [Dockerfile](/Users/ab69/AMRC-R-package/Dockerfile)
- [render.yaml](/Users/ab69/AMRC-R-package/render.yaml)

To deploy on Render:

1. Connect the GitHub repository in Render.
2. Create a new Web Service.
3. Choose the Docker runtime.
4. Let Render build from the repo Dockerfile.
5. Use the default command from the Dockerfile.

Render requires the service to bind on `0.0.0.0`, which the Dockerfile already
does. See [Render Web Services](https://render.com/docs/web-services) and
[Render Docker deployment](https://render.com/docs/docker).

## Streamlit Community Cloud

This may be possible because Community Cloud supports `requirements.txt` plus
Linux packages via `packages.txt`, but this app is less natural there because
it needs a full R runtime in addition to Python. See [Streamlit app
dependencies](https://docs.streamlit.io/deploy/streamlit-community-cloud/deploy-your-app/app-dependencies)
and [deploying on Community Cloud](https://docs.streamlit.io/deploy/streamlit-community-cloud/deploy-your-app/deploy).

If you want the fastest route to a public URL, use Render first.
