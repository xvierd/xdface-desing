.PHONY: dev build deploy deploy-infra invalidate

DIST_ID := $(shell aws-vault exec theants -- aws ssm get-parameter \
  --name /xdface/design/cf-distribution-id \
  --query Parameter.Value --output text --region us-east-1 2>/dev/null)

BUCKET := $(shell aws-vault exec theants -- aws ssm get-parameter \
  --name /xdface/design/bucket-name \
  --query Parameter.Value --output text --region us-east-1 2>/dev/null)

dev:
	cd web && npm run dev

build:
	cp web/src/styles/global.css web/public/styles/global.css
	cd web && npm run build

deploy: build
	aws-vault exec theants -- aws s3 sync web/dist/ s3://$(BUCKET)/ --delete
	aws-vault exec theants -- aws s3 cp web/dist/index.html s3://$(BUCKET)/index.html \
	  --cache-control "no-cache, no-store, must-revalidate"
	aws-vault exec theants -- aws cloudfront create-invalidation \
	  --distribution-id $(DIST_ID) --paths "/*"
	@echo "Deployed to https://design.xdface.net"

deploy-infra:
	cd ../site/infra && aws-vault exec theants -- npx cdk deploy XdfaceDesignStack

invalidate:
	aws-vault exec theants -- aws cloudfront create-invalidation \
	  --distribution-id $(DIST_ID) --paths "/*"
