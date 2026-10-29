# Basic Usage

```dart
BillingConnector.instance.GetBillingAdmission(getBillingAdmissionVariables).execute();
BillingConnector.instance.CreateBillingAdmission(createBillingAdmissionVariables).execute();
BillingConnector.instance.BindBillingAdmissionRun(bindBillingAdmissionRunVariables).execute();
BillingConnector.instance.ExpireBillingAdmission(expireBillingAdmissionVariables).execute();
BillingConnector.instance.CreateBillingCheckoutCreation(createBillingCheckoutCreationVariables).execute();
BillingConnector.instance.GetOpenBillingCheckoutCreation(getOpenBillingCheckoutCreationVariables).execute();
BillingConnector.instance.RecordBillingCheckoutSession(recordBillingCheckoutSessionVariables).execute();
BillingConnector.instance.CloseBillingCheckoutCreation(closeBillingCheckoutCreationVariables).execute();
BillingConnector.instance.GetBillingContext(getBillingContextVariables).execute();
BillingConnector.instance.GetBillingCustomerByStripeId(getBillingCustomerByStripeIdVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await BillingConnector.instance.StartBillingTrial({ ... })
.allowanceSeconds(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.
