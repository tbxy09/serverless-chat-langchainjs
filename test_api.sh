#!/bin/bash
echo "Testing the Azure OpenAI API..."
# print the environment variables
source packages/api/.env
echo $AZURE_OPENAI_API_ENDPOINT
curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${AZURE_OPENAI_API_KEY}" \
    -d '{"prompt": "Hello, how are you?", "max_tokens": 50}' \
    "$AZURE_OPENAI_API_ENDPOINT"