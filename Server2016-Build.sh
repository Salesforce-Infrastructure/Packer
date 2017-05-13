# Build Images
packer build -var-file=Server2016-Variables.json 01-OperatingSystem.json \
    && packer build -var-file=Server2016-Variables.json 02-BaseSoftware-MSUpdates.json \
    && packer build -var-file=Server2016-Variables.json 03-Cleanup-Sysprep-Finalize.json \
