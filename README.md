# Readme
Currently, this repository should only be used for generating Server 2016 images.

In order to do so, perform the following steps.

(For Virtualbox Image)
Steps:
  - Create a subdirectory named "ISO", and another named "Output".
  - Within the ISO directory, place the en_windows_server_2016_x64_dvd_9718492.iso file.
  - Run `packer build --force --only=virtualbox-iso --var-file Server2016-Variables.json --var Output_Directory=Output 01-OperatingSystem.json`
  - Next, run `packer build --only=virtualbox-ovf --var-file Server2016-Variables.json --var Output_Directory=Output 02-BaseSoftware-MSUpdates.json`
  - `packer build 03-Cleanup.json`
  - Lastly, run `packer build --only=virtualbox-ovf --var-file Server2016-Variables.json --var Output_Directory=Output 03-Cleanup-Sysprep-Capture.json`

If you'd only like to build the VMware image, or Virtualbox Images, you can do something like
`packer build --only=vmware-vmx 01-Windows2008R2-Base.json`

Do do:
 - Migrate MaaS network script to exist in this repo as it is not needed here.
 - Add Process to Handle Versioning Within The Packer Process, Preferably automated and self-incrementing.
 - Investigate if it is possible to get around the VMware winrm issue.
 - Add ability to exclude software updates.
 - Add ability to automatically uploat to Atlas or an HTTP source.
