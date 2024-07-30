name: Build and deploy ASP.Net Core app to Azure Web App - app-backend-besportsmart

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  APP_NAME: '${ app_name }'
  DOTNET_VERSION: '8.x'
  DOTNET_CONFIG: 'Release'
  DEPLOYMENT_ENVIRONMENT: 'Production'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: 'Production'
      url: ${{ steps.deploy-to-webapp.outputs.webapp-url }}
    permissions:
      contents: read
      deployments: write
      id-token: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up .NET Core
        uses: actions/setup-dotnet@v1
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
          include-prerelease: true

      - name: Build with dotnet
        run: dotnet build --configuration ${{ env.DOTNET_CONFIG }}

      - name: dotnet publish
        run: dotnet publish -c ${{ env.DOTNET_CONFIG }} -o ${{ env.DOTNET_ROOT }}/app

      - name: Login to Azure
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZUREAPPSERVICE_CLIENTID }}
          tenant-id: ${{ secrets.AZUREAPPSERVICE_TENANTID }}
          subscription-id: ${{ secrets.AZUREAPPSERVICE_SUBSCRIPTIONID }}

      - name: Deploy to Azure Web App
        id: deploy-to-webapp
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.APP_NAME }}
          slot-name: ${{ env.DEPLOYMENT_ENVIRONMENT }}
          package: ${{ env.DOTNET_ROOT }}/app
