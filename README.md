# pool-utils

## Kes Rotation Validator
### Clonme the repository and maintain your rotation-history.json file

A bash script to validate your files after a kes rotation.

Usage
- Check out to your bp node in same directory as yoru kes and node cert
- Update the script with your node.cert and kes.skey file locations (relative paths are fine e.g. ../kes.skey)
- chmod +x checkKesRotation.sh (make the script executable)
- ./checkKesRotation.sh

Use cases covered
- Kes file has been regenerated but node certificate was not updated
- Node certificate has been updated but kes file has not been updated
- Node certificate was genereted with read only node.counter file
- Node certificate was generated with a stale node.counter file (retrieved from backup)

Use cases not covered
- The node.cert was generated using the wrong kes.vkey (I'll investigate if this is possible to validate)

The script will inspect the node certificate and obtain the current rotation increment. 
If the increment is greater than the maximum increment in the rotation-history.json file, it will validate the node certificate has not been recorded in the history and that the kes signing key has not been recorded in history. 
A new record will be added to the history on successful validation.
A validation failure will show a warning.

If the increment is equal to the maximum increment in the history, then the node certificate and kes signing key files will be compared to those in the most recent history entry.
A validation failure will show a warning.

If the increment is less than the maximum recorder increment then a warning will be shown


