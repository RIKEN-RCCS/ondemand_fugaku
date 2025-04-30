# Batch Connect Shell

This application is obtain from https://code.oscer.ou.edu/OnDemand/ood-apps-nmsu/-/tree/main/shell

## Security
- ttyd password is visible in /proc (ps command) due to the password being passed directly in the call.
  - To mitigate this impliment the 'hidepid' mount option to '/proc' in order to prevent users from seeing processes that do not belong to them.
    - [RHEL 7+ reccomends against using hidepid](https://access.redhat.com/solutions/6704531) so another solution is likely needed.
- To solve this problem, -m 1 is added to the ttyd option. This option ensures that only one client can connect.