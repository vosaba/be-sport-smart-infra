name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main
  workflow_dispatch:

env:
  VITE_BACKEND_BASE_URL: $${{ vars.${ backend_base_url_key } }}
  VITE_DYNAMIC_LOCALIZATION_BASE_URL: $${{ vars.${ dynamic_localization_base_url_key } }}
  VITE_APPLICATIONINSIGHTS_CONNECTION_STRING: $${{ vars.${ applicationinsights_connection_string_key } }}

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy Job
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true
      # - name: setup vue environment file
      #   run: |
      #     echo "VUE_APP_NOT_SECRET_CODE=some_value" >  $GITHUB_WORKSPACE/.env
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v0.0.1-preview
        with:
          azure_static_web_apps_api_token: $${{ secrets.${ app_token_key } }}
          repo_token: $${{ secrets.${ github_token_key } }} # Used for Github integrations (i.e. PR comments)
          action: "upload"
          ###### Repository/Build Configurations - These values can be configured to match you app requirements. ######
          # For more information regarding Static Web App workflow configurations, please visit: https://aka.ms/swaworkflowconfig
          app_location: "${ app_location }" # App source code path
          output_location: "${ output_location }" # Built app content directory - optional
          ###### End of Repository/Build Configurations ######

  close_pull_request_job:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    name: Close Pull Request Job
    steps:
      - name: Close Pull Request
        id: closepullrequest
        uses: Azure/static-web-apps-deploy@v0.0.1-preview
        with:
          azure_static_web_apps_api_token: $${{ secrets.${ app_token_key } }}
          action: "close"