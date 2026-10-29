library billing;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'get_billing_admission.dart';

part 'create_billing_admission.dart';

part 'bind_billing_admission_run.dart';

part 'expire_billing_admission.dart';

part 'create_billing_checkout_creation.dart';

part 'get_open_billing_checkout_creation.dart';

part 'record_billing_checkout_session.dart';

part 'close_billing_checkout_creation.dart';

part 'get_billing_context.dart';

part 'get_billing_customer_by_stripe_id.dart';

part 'get_billing_checkout_creation.dart';

part 'get_billing_period.dart';

part 'create_billing_customer_creation.dart';

part 'get_billing_customer_creation.dart';

part 'record_billing_customer.dart';

part 'delete_billing_team.dart';

part 'get_billing_execution.dart';

part 'start_billing_execution.dart';

part 'heartbeat_billing_execution.dart';

part 'finish_billing_execution.dart';

part 'expire_billing_execution.dart';

part 'get_expired_billing_work.dart';

part 'get_queued_billing_jobs.dart';

part 'get_billing_worker_jobs.dart';

part 'get_billing_job.dart';

part 'create_billing_period.dart';

part 'get_billing_stripe_state.dart';

part 'get_billing_stripe_event.dart';

part 'initialize_billing_stripe_state.dart';

part 'record_billing_stripe_event.dart';

part 'get_billing_trial_eligibility.dart';

part 'start_billing_trial.dart';

part 'get_billing_period_usage.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class BillingConnector {
  GetBillingAdmissionVariablesBuilder getBillingAdmission({
    required String teamId,
    required String id,
  }) {
    return GetBillingAdmissionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      id: id,
    );
  }

  CreateBillingAdmissionVariablesBuilder createBillingAdmission({
    required String id,
    required String teamId,
    required String jobId,
    required String workerHost,
    required String periodId,
    required BigInt atMs,
  }) {
    return CreateBillingAdmissionVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      periodId: periodId,
      atMs: atMs,
    );
  }

  BindBillingAdmissionRunVariablesBuilder bindBillingAdmissionRun({
    required String id,
    required String teamId,
    required String jobId,
    required String workerHost,
    required String runId,
    required BigInt expectedUsageRevision,
    required BigInt atMs,
  }) {
    return BindBillingAdmissionRunVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
  }

  ExpireBillingAdmissionVariablesBuilder expireBillingAdmission({
    required String id,
    required String teamId,
    required BigInt expectedUsageRevision,
    required BigInt atMs,
  }) {
    return ExpireBillingAdmissionVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
  }

  CreateBillingCheckoutCreationVariablesBuilder createBillingCheckoutCreation({
    required String idempotencyKey,
    required String teamId,
    required String planId,
    required String stripeCustomerId,
    required String stripePriceId,
    required String successUrl,
    required String cancelUrl,
    required bool livemode,
    required BigInt createdAt,
  }) {
    return CreateBillingCheckoutCreationVariablesBuilder(
      dataConnect,
      idempotencyKey: idempotencyKey,
      teamId: teamId,
      planId: planId,
      stripeCustomerId: stripeCustomerId,
      stripePriceId: stripePriceId,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
      livemode: livemode,
      createdAt: createdAt,
    );
  }

  GetOpenBillingCheckoutCreationVariablesBuilder
  getOpenBillingCheckoutCreation({
    required String teamId,
    required bool livemode,
  }) {
    return GetOpenBillingCheckoutCreationVariablesBuilder(
      dataConnect,
      teamId: teamId,
      livemode: livemode,
    );
  }

  RecordBillingCheckoutSessionVariablesBuilder recordBillingCheckoutSession({
    required String idempotencyKey,
    required String teamId,
    required String planId,
    required String stripeCustomerId,
    required String stripePriceId,
    required String successUrl,
    required String cancelUrl,
    required bool livemode,
    required BigInt createdAt,
    required String stripeCheckoutSessionId,
  }) {
    return RecordBillingCheckoutSessionVariablesBuilder(
      dataConnect,
      idempotencyKey: idempotencyKey,
      teamId: teamId,
      planId: planId,
      stripeCustomerId: stripeCustomerId,
      stripePriceId: stripePriceId,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
      livemode: livemode,
      createdAt: createdAt,
      stripeCheckoutSessionId: stripeCheckoutSessionId,
    );
  }

  CloseBillingCheckoutCreationVariablesBuilder closeBillingCheckoutCreation({
    required String idempotencyKey,
    required String teamId,
    required String stripeCustomerId,
    required bool livemode,
    required String stripeCheckoutSessionId,
    required BigInt closedAt,
  }) {
    return CloseBillingCheckoutCreationVariablesBuilder(
      dataConnect,
      idempotencyKey: idempotencyKey,
      teamId: teamId,
      stripeCustomerId: stripeCustomerId,
      livemode: livemode,
      stripeCheckoutSessionId: stripeCheckoutSessionId,
      closedAt: closedAt,
    );
  }

  GetBillingContextVariablesBuilder getBillingContext({
    required String teamId,
    required String userId,
  }) {
    return GetBillingContextVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
    );
  }

  GetBillingCustomerByStripeIdVariablesBuilder getBillingCustomerByStripeId({
    required String stripeCustomerId,
    required bool livemode,
  }) {
    return GetBillingCustomerByStripeIdVariablesBuilder(
      dataConnect,
      stripeCustomerId: stripeCustomerId,
      livemode: livemode,
    );
  }

  GetBillingCheckoutCreationVariablesBuilder getBillingCheckoutCreation({
    required String teamId,
    required String idempotencyKey,
    required bool livemode,
  }) {
    return GetBillingCheckoutCreationVariablesBuilder(
      dataConnect,
      teamId: teamId,
      idempotencyKey: idempotencyKey,
      livemode: livemode,
    );
  }

  GetBillingPeriodVariablesBuilder getBillingPeriod({
    required String teamId,
    required String id,
  }) {
    return GetBillingPeriodVariablesBuilder(
      dataConnect,
      teamId: teamId,
      id: id,
    );
  }

  CreateBillingCustomerCreationVariablesBuilder createBillingCustomerCreation({
    required String teamId,
    required String idempotencyKey,
    required bool livemode,
    required BigInt createdAt,
  }) {
    return CreateBillingCustomerCreationVariablesBuilder(
      dataConnect,
      teamId: teamId,
      idempotencyKey: idempotencyKey,
      livemode: livemode,
      createdAt: createdAt,
    );
  }

  GetBillingCustomerCreationVariablesBuilder getBillingCustomerCreation({
    required String teamId,
    required bool livemode,
  }) {
    return GetBillingCustomerCreationVariablesBuilder(
      dataConnect,
      teamId: teamId,
      livemode: livemode,
    );
  }

  RecordBillingCustomerVariablesBuilder recordBillingCustomer({
    required String teamId,
    required String idempotencyKey,
    required bool livemode,
    required String stripeCustomerId,
  }) {
    return RecordBillingCustomerVariablesBuilder(
      dataConnect,
      teamId: teamId,
      idempotencyKey: idempotencyKey,
      livemode: livemode,
      stripeCustomerId: stripeCustomerId,
    );
  }

  DeleteBillingTeamVariablesBuilder deleteBillingTeam({
    required String teamId,
    required String userId,
    required bool livemode,
  }) {
    return DeleteBillingTeamVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
      livemode: livemode,
    );
  }

  GetBillingExecutionVariablesBuilder getBillingExecution({
    required String teamId,
    required String runId,
  }) {
    return GetBillingExecutionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
    );
  }

  StartBillingExecutionVariablesBuilder startBillingExecution({
    required String admissionId,
    required String teamId,
    required String jobId,
    required String workerHost,
    required String runId,
    required BigInt expectedUsageRevision,
    required BigInt atMs,
  }) {
    return StartBillingExecutionVariablesBuilder(
      dataConnect,
      admissionId: admissionId,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
  }

  HeartbeatBillingExecutionVariablesBuilder heartbeatBillingExecution({
    required String teamId,
    required String jobId,
    required String workerHost,
    required String runId,
    required BigInt expectedUsageRevision,
    required BigInt atMs,
  }) {
    return HeartbeatBillingExecutionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
  }

  FinishBillingExecutionVariablesBuilder finishBillingExecution({
    required String teamId,
    required String jobId,
    required String workerHost,
    required String runId,
    required BigInt expectedUsageRevision,
    required BigInt atMs,
    required String outcome,
  }) {
    return FinishBillingExecutionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      jobId: jobId,
      workerHost: workerHost,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
      outcome: outcome,
    );
  }

  ExpireBillingExecutionVariablesBuilder expireBillingExecution({
    required String teamId,
    required String runId,
    required BigInt expectedUsageRevision,
    required BigInt atMs,
  }) {
    return ExpireBillingExecutionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      runId: runId,
      expectedUsageRevision: expectedUsageRevision,
      atMs: atMs,
    );
  }

  GetExpiredBillingWorkVariablesBuilder getExpiredBillingWork({
    required BigInt atMs,
  }) {
    return GetExpiredBillingWorkVariablesBuilder(
      dataConnect,
      atMs: atMs,
    );
  }

  GetQueuedBillingJobsVariablesBuilder getQueuedBillingJobs() {
    return GetQueuedBillingJobsVariablesBuilder(
      dataConnect,
    );
  }

  GetBillingWorkerJobsVariablesBuilder getBillingWorkerJobs({
    required String workerHost,
  }) {
    return GetBillingWorkerJobsVariablesBuilder(
      dataConnect,
      workerHost: workerHost,
    );
  }

  GetBillingJobVariablesBuilder getBillingJob({
    required String id,
  }) {
    return GetBillingJobVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  CreateBillingPeriodVariablesBuilder createBillingPeriod({
    required String id,
    required String teamId,
    required String planId,
    required String periodType,
    required BigInt startsAt,
    required BigInt endsAt,
  }) {
    return CreateBillingPeriodVariablesBuilder(
      dataConnect,
      id: id,
      teamId: teamId,
      planId: planId,
      periodType: periodType,
      startsAt: startsAt,
      endsAt: endsAt,
    );
  }

  GetBillingStripeStateVariablesBuilder getBillingStripeState({
    required String teamId,
    required bool livemode,
  }) {
    return GetBillingStripeStateVariablesBuilder(
      dataConnect,
      teamId: teamId,
      livemode: livemode,
    );
  }

  GetBillingStripeEventVariablesBuilder getBillingStripeEvent({
    required String eventId,
  }) {
    return GetBillingStripeEventVariablesBuilder(
      dataConnect,
      eventId: eventId,
    );
  }

  InitializeBillingStripeStateVariablesBuilder initializeBillingStripeState({
    required String teamId,
    required String stripeCustomerId,
    required bool livemode,
  }) {
    return InitializeBillingStripeStateVariablesBuilder(
      dataConnect,
      teamId: teamId,
      stripeCustomerId: stripeCustomerId,
      livemode: livemode,
    );
  }

  RecordBillingStripeEventVariablesBuilder recordBillingStripeEvent({
    required String teamId,
    required String stripeCustomerId,
    required bool livemode,
    required BigInt expectedRevision,
    required String subscriptionStatus,
    required bool cancelAtPeriodEnd,
    required String eventId,
    required String eventType,
    required BigInt eventCreated,
    required BigInt processedAt,
  }) {
    return RecordBillingStripeEventVariablesBuilder(
      dataConnect,
      teamId: teamId,
      stripeCustomerId: stripeCustomerId,
      livemode: livemode,
      expectedRevision: expectedRevision,
      subscriptionStatus: subscriptionStatus,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      eventId: eventId,
      eventType: eventType,
      eventCreated: eventCreated,
      processedAt: processedAt,
    );
  }

  GetBillingTrialEligibilityVariablesBuilder getBillingTrialEligibility({
    required String teamId,
    required String userId,
  }) {
    return GetBillingTrialEligibilityVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
    );
  }

  StartBillingTrialVariablesBuilder startBillingTrial({
    required String teamId,
    required String userId,
    required String periodId,
  }) {
    return StartBillingTrialVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
      periodId: periodId,
    );
  }

  GetBillingPeriodUsageVariablesBuilder getBillingPeriodUsage({
    required String teamId,
    required String periodId,
    required BigInt atMs,
  }) {
    return GetBillingPeriodUsageVariablesBuilder(
      dataConnect,
      teamId: teamId,
      periodId: periodId,
      atMs: atMs,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'billing',
    'openci-b1b91-service',
  );

  BillingConnector({required this.dataConnect});
  static BillingConnector get instance {
    return BillingConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
