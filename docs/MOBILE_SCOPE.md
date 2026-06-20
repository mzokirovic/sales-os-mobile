# Sales OS Mobile Scope v1

Mobile app is a field-work app, not a full admin panel.

## Primary mobile workflows

- Login by role
- View dashboard summary
- View orders
- View order detail
- Create order where allowed
- Update fulfillment status where allowed
- Add payment where allowed
- View customers
- View customer detail
- Create customer where allowed

## Product catalog

Products should be available as read-only catalog in mobile.

Allowed roles:

- OWNER
- MANAGER
- SALES
- OPERATOR
- WAREHOUSE

Not included in mobile v1:

- Product create/edit/archive
- Employee management

Those remain in the web admin panel.

## Employees

Employee management stays web-only for now.

Reason:

- It is an admin/back-office workflow
- Mobile should stay compact and field-focused
- Backend remains the source of truth for permissions
