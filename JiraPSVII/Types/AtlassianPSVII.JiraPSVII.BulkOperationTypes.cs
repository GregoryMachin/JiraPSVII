// Typed DTOs for Jira Cloud issue bulk operation requests and status output.
// These models intentionally do not submit requests; public commands will
// consume them in later tasks.

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Security;
using System.Management.Automation;

namespace AtlassianPSVII.JiraPSVII
{
    public enum BulkIssueOperation
    {
        Edit,
        Move,
        Delete
    }

    public enum BulkEditMultiSelectFieldOption
    {
        ADD,
        REMOVE,
        REPLACE,
        REMOVE_ALL
    }

    public enum BulkOperationStatus
    {
        RUNNING,
        COMPLETE,
        FAILED,
        NOT_FOUND
    }

    public static class BulkOperationLimits
    {
        public const int MaxIssueCount = 1000;
        public const int MaxEditFieldCount = 200;
    }

    internal static class BulkOperationPayload
    {
        public static OrderedDictionary NewPayload()
        {
            return new OrderedDictionary(StringComparer.Ordinal);
        }

        public static void AddIfNotNull(OrderedDictionary payload, string name, object value)
        {
            if (value == null) { return; }
            payload.Add(name, value);
        }

        public static void AddIfHasValue(OrderedDictionary payload, string name, bool? value)
        {
            if (value.HasValue) { payload.Add(name, value.Value); }
        }

        public static int CountArray(Array values)
        {
            return values == null ? 0 : values.Length;
        }

        public static void ValidateIssueIds(string[] issueIdsOrKeys, string propertyName)
        {
            if (issueIdsOrKeys == null || issueIdsOrKeys.Length == 0)
            {
                throw new ArgumentException(propertyName + " must include at least one issue ID or key.", propertyName);
            }
            if (issueIdsOrKeys.Length > BulkOperationLimits.MaxIssueCount)
            {
                throw new ArgumentOutOfRangeException(
                    propertyName,
                    issueIdsOrKeys.Length,
                    "Bulk issue operations support at most 1,000 issues per request.");
            }

            for (var i = 0; i < issueIdsOrKeys.Length; i++)
            {
                if (string.IsNullOrWhiteSpace(issueIdsOrKeys[i]))
                {
                    throw new ArgumentException(propertyName + " must not contain null, empty, or whitespace issue IDs or keys.", propertyName);
                }
            }
        }

        public static void ValidateSerializableValue(object value, string path)
        {
            if (value == null) { return; }

            var pso = value as PSObject;
            if (pso != null)
            {
                ValidateSerializableValue(pso.BaseObject, path);
                return;
            }

            if (value is ScriptBlock || value is PSCredential || value is SecureString)
            {
                throw new ArgumentException("Bulk operation payload value '" + path + "' must not contain credentials, secure strings, or script blocks.", path);
            }

            var dictionary = value as IDictionary;
            if (dictionary != null)
            {
                foreach (DictionaryEntry entry in dictionary)
                {
                    ValidateSerializableValue(entry.Value, path + "." + (entry.Key != null ? entry.Key.ToString() : "<null>"));
                }
                return;
            }

            var enumerable = value as IEnumerable;
            if (enumerable != null && !(value is string))
            {
                var index = 0;
                foreach (var item in enumerable)
                {
                    ValidateSerializableValue(item, path + "[" + index.ToString(System.Globalization.CultureInfo.InvariantCulture) + "]");
                    index++;
                }
            }
        }
    }

    public abstract class BulkIssueRequest
    {
        public abstract BulkIssueOperation Operation { get; }
        public string[] SelectedIssueIdsOrKeys { get; set; }
        public bool? SendBulkNotification { get; set; }

        public abstract OrderedDictionary ToJiraPayload();

        protected void ValidateSelectedIssues()
        {
            BulkOperationPayload.ValidateIssueIds(SelectedIssueIdsOrKeys, "SelectedIssueIdsOrKeys");
        }
    }

    public sealed class BulkIssueDeleteRequest : BulkIssueRequest
    {
        public override BulkIssueOperation Operation { get { return BulkIssueOperation.Delete; } }

        public BulkIssueDeleteRequest() { }

        public override OrderedDictionary ToJiraPayload()
        {
            ValidateSelectedIssues();

            var payload = BulkOperationPayload.NewPayload();
            payload.Add("selectedIssueIdsOrKeys", SelectedIssueIdsOrKeys);
            BulkOperationPayload.AddIfHasValue(payload, "sendBulkNotification", SendBulkNotification);
            return payload;
        }
    }

    public sealed class BulkIssueEditRequest : BulkIssueRequest
    {
        public override BulkIssueOperation Operation { get { return BulkIssueOperation.Edit; } }
        public JiraBulkEditFieldsInput EditedFieldsInput { get; set; }
        public string[] SelectedActions { get; set; }

        public BulkIssueEditRequest() { }

        public override OrderedDictionary ToJiraPayload()
        {
            ValidateSelectedIssues();
            if (EditedFieldsInput == null)
            {
                throw new ArgumentException("EditedFieldsInput must not be null.", "EditedFieldsInput");
            }
            if (SelectedActions == null || SelectedActions.Length == 0)
            {
                throw new ArgumentException("SelectedActions must include at least one selected bulk edit action.", "SelectedActions");
            }
            for (var i = 0; i < SelectedActions.Length; i++)
            {
                if (string.IsNullOrWhiteSpace(SelectedActions[i]))
                {
                    throw new ArgumentException("SelectedActions must not contain null, empty, or whitespace actions.", "SelectedActions");
                }
            }

            var fieldCount = EditedFieldsInput.GetFieldUpdateCount();
            if (fieldCount == 0)
            {
                throw new ArgumentException("EditedFieldsInput must include at least one field update.", "EditedFieldsInput");
            }
            if (fieldCount > BulkOperationLimits.MaxEditFieldCount)
            {
                throw new ArgumentOutOfRangeException(
                    "EditedFieldsInput",
                    fieldCount,
                    "Bulk edit operations support at most 200 fields per request.");
            }

            var editedPayload = EditedFieldsInput.ToJiraPayload();
            BulkOperationPayload.ValidateSerializableValue(editedPayload, "EditedFieldsInput");

            var payload = BulkOperationPayload.NewPayload();
            payload.Add("editedFieldsInput", editedPayload);
            payload.Add("selectedActions", SelectedActions);
            payload.Add("selectedIssueIdsOrKeys", SelectedIssueIdsOrKeys);
            BulkOperationPayload.AddIfHasValue(payload, "sendBulkNotification", SendBulkNotification);
            return payload;
        }
    }

    public sealed class BulkIssueMoveRequest
    {
        public BulkIssueOperation Operation { get { return BulkIssueOperation.Move; } }
        public bool? SendBulkNotification { get; set; }
        public IDictionary TargetToSourcesMapping { get; set; }

        public BulkIssueMoveRequest() { }

        public OrderedDictionary ToJiraPayload()
        {
            if (TargetToSourcesMapping == null || TargetToSourcesMapping.Count == 0)
            {
                throw new ArgumentException("TargetToSourcesMapping must include at least one target mapping.", "TargetToSourcesMapping");
            }

            var issueCount = 0;
            var mappings = BulkOperationPayload.NewPayload();
            foreach (DictionaryEntry entry in TargetToSourcesMapping)
            {
                var key = entry.Key != null ? entry.Key.ToString() : string.Empty;
                if (string.IsNullOrWhiteSpace(key))
                {
                    throw new ArgumentException("TargetToSourcesMapping keys must not be null, empty, or whitespace.", "TargetToSourcesMapping");
                }

                var target = entry.Value as BulkIssueMoveTarget;
                if (target == null)
                {
                    throw new ArgumentException("TargetToSourcesMapping values must be AtlassianPSVII.JiraPSVII.BulkIssueMoveTarget objects.", "TargetToSourcesMapping");
                }

                issueCount += target.IssueIdsOrKeys == null ? 0 : target.IssueIdsOrKeys.Length;
                mappings.Add(key, target.ToJiraPayload());
            }

            if (issueCount > BulkOperationLimits.MaxIssueCount)
            {
                throw new ArgumentOutOfRangeException(
                    "TargetToSourcesMapping",
                    issueCount,
                    "Bulk move operations support at most 1,000 issues per request.");
            }

            BulkOperationPayload.ValidateSerializableValue(mappings, "TargetToSourcesMapping");

            var payload = BulkOperationPayload.NewPayload();
            BulkOperationPayload.AddIfHasValue(payload, "sendBulkNotification", SendBulkNotification);
            payload.Add("targetToSourcesMapping", mappings);
            return payload;
        }
    }

    public sealed class BulkIssueMoveTarget
    {
        public bool? InferClassificationDefaults { get; set; }
        public bool? InferFieldDefaults { get; set; }
        public bool? InferStatusDefaults { get; set; }
        public bool? InferSubtaskTypeDefault { get; set; }
        public string[] IssueIdsOrKeys { get; set; }
        public object[] TargetClassification { get; set; }
        public object[] TargetMandatoryFields { get; set; }
        public object[] TargetStatus { get; set; }

        public BulkIssueMoveTarget() { }

        public OrderedDictionary ToJiraPayload()
        {
            BulkOperationPayload.ValidateIssueIds(IssueIdsOrKeys, "IssueIdsOrKeys");

            var payload = BulkOperationPayload.NewPayload();
            BulkOperationPayload.AddIfHasValue(payload, "inferClassificationDefaults", InferClassificationDefaults);
            BulkOperationPayload.AddIfHasValue(payload, "inferFieldDefaults", InferFieldDefaults);
            BulkOperationPayload.AddIfHasValue(payload, "inferStatusDefaults", InferStatusDefaults);
            BulkOperationPayload.AddIfHasValue(payload, "inferSubtaskTypeDefault", InferSubtaskTypeDefault);
            payload.Add("issueIdsOrKeys", IssueIdsOrKeys);
            BulkOperationPayload.AddIfNotNull(payload, "targetClassification", TargetClassification);
            BulkOperationPayload.AddIfNotNull(payload, "targetMandatoryFields", TargetMandatoryFields);
            BulkOperationPayload.AddIfNotNull(payload, "targetStatus", TargetStatus);
            return payload;
        }
    }

    public sealed class JiraBulkEditFieldsInput
    {
        private static readonly Dictionary<string, string> AllowedFields = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "CascadingSelectFields", "cascadingSelectFields" },
            { "ClearableNumberFields", "clearableNumberFields" },
            { "ColorFields", "colorFields" },
            { "DatePickerFields", "datePickerFields" },
            { "DateTimePickerFields", "dateTimePickerFields" },
            { "IssueType", "issueType" },
            { "LabelsFields", "labelsFields" },
            { "MultipleGroupPickerFields", "multipleGroupPickerFields" },
            { "MultipleSelectClearableUserPickerFields", "multipleSelectClearableUserPickerFields" },
            { "MultipleSelectFields", "multipleSelectFields" },
            { "MultipleVersionPickerFields", "multipleVersionPickerFields" },
            { "MultiselectComponents", "multiselectComponents" },
            { "OriginalEstimateField", "originalEstimateField" },
            { "Priority", "priority" },
            { "RichTextFields", "richTextFields" },
            { "SingleGroupPickerFields", "singleGroupPickerFields" },
            { "SingleLineTextFields", "singleLineTextFields" },
            { "SingleSelectClearableUserPickerFields", "singleSelectClearableUserPickerFields" },
            { "SingleSelectFields", "singleSelectFields" },
            { "SingleVersionPickerFields", "singleVersionPickerFields" },
            { "Status", "status" },
            { "TimeTrackingField", "timeTrackingField" },
            { "UrlFields", "urlFields" }
        };

        public object[] CascadingSelectFields { get; set; }
        public object[] ClearableNumberFields { get; set; }
        public object[] ColorFields { get; set; }
        public object[] DatePickerFields { get; set; }
        public object[] DateTimePickerFields { get; set; }
        public object IssueType { get; set; }
        public object[] LabelsFields { get; set; }
        public object[] MultipleGroupPickerFields { get; set; }
        public object[] MultipleSelectClearableUserPickerFields { get; set; }
        public object[] MultipleSelectFields { get; set; }
        public object[] MultipleVersionPickerFields { get; set; }
        public object MultiselectComponents { get; set; }
        public object OriginalEstimateField { get; set; }
        public object Priority { get; set; }
        public object[] RichTextFields { get; set; }
        public object[] SingleGroupPickerFields { get; set; }
        public object[] SingleLineTextFields { get; set; }
        public object[] SingleSelectClearableUserPickerFields { get; set; }
        public object[] SingleSelectFields { get; set; }
        public object[] SingleVersionPickerFields { get; set; }
        public object Status { get; set; }
        public object TimeTrackingField { get; set; }
        public object[] UrlFields { get; set; }

        public JiraBulkEditFieldsInput() { }

        public static JiraBulkEditFieldsInput FromDictionary(IDictionary input)
        {
            if (input == null)
            {
                throw new ArgumentNullException("input");
            }

            var fields = new JiraBulkEditFieldsInput();
            foreach (DictionaryEntry entry in input)
            {
                var key = entry.Key != null ? entry.Key.ToString() : string.Empty;
                if (!AllowedFields.ContainsKey(key))
                {
                    throw new ArgumentException("Unknown bulk edit field collection '" + key + "'.", "input");
                }

                fields.SetProperty(key, entry.Value);
            }
            return fields;
        }

        public int GetFieldUpdateCount()
        {
            return BulkOperationPayload.CountArray(CascadingSelectFields)
                + BulkOperationPayload.CountArray(ClearableNumberFields)
                + BulkOperationPayload.CountArray(ColorFields)
                + BulkOperationPayload.CountArray(DatePickerFields)
                + BulkOperationPayload.CountArray(DateTimePickerFields)
                + CountScalar(IssueType)
                + BulkOperationPayload.CountArray(LabelsFields)
                + BulkOperationPayload.CountArray(MultipleGroupPickerFields)
                + BulkOperationPayload.CountArray(MultipleSelectClearableUserPickerFields)
                + BulkOperationPayload.CountArray(MultipleSelectFields)
                + BulkOperationPayload.CountArray(MultipleVersionPickerFields)
                + CountScalar(MultiselectComponents)
                + CountScalar(OriginalEstimateField)
                + CountScalar(Priority)
                + BulkOperationPayload.CountArray(RichTextFields)
                + BulkOperationPayload.CountArray(SingleGroupPickerFields)
                + BulkOperationPayload.CountArray(SingleLineTextFields)
                + BulkOperationPayload.CountArray(SingleSelectClearableUserPickerFields)
                + BulkOperationPayload.CountArray(SingleSelectFields)
                + BulkOperationPayload.CountArray(SingleVersionPickerFields)
                + CountScalar(Status)
                + CountScalar(TimeTrackingField)
                + BulkOperationPayload.CountArray(UrlFields);
        }

        public OrderedDictionary ToJiraPayload()
        {
            var payload = BulkOperationPayload.NewPayload();
            AddPayload(payload, "cascadingSelectFields", CascadingSelectFields);
            AddPayload(payload, "clearableNumberFields", ClearableNumberFields);
            AddPayload(payload, "colorFields", ColorFields);
            AddPayload(payload, "datePickerFields", DatePickerFields);
            AddPayload(payload, "dateTimePickerFields", DateTimePickerFields);
            AddPayload(payload, "issueType", IssueType);
            AddPayload(payload, "labelsFields", LabelsFields);
            AddPayload(payload, "multipleGroupPickerFields", MultipleGroupPickerFields);
            AddPayload(payload, "multipleSelectClearableUserPickerFields", MultipleSelectClearableUserPickerFields);
            AddPayload(payload, "multipleSelectFields", MultipleSelectFields);
            AddPayload(payload, "multipleVersionPickerFields", MultipleVersionPickerFields);
            AddPayload(payload, "multiselectComponents", MultiselectComponents);
            AddPayload(payload, "originalEstimateField", OriginalEstimateField);
            AddPayload(payload, "priority", Priority);
            AddPayload(payload, "richTextFields", RichTextFields);
            AddPayload(payload, "singleGroupPickerFields", SingleGroupPickerFields);
            AddPayload(payload, "singleLineTextFields", SingleLineTextFields);
            AddPayload(payload, "singleSelectClearableUserPickerFields", SingleSelectClearableUserPickerFields);
            AddPayload(payload, "singleSelectFields", SingleSelectFields);
            AddPayload(payload, "singleVersionPickerFields", SingleVersionPickerFields);
            AddPayload(payload, "status", Status);
            AddPayload(payload, "timeTrackingField", TimeTrackingField);
            AddPayload(payload, "urlFields", UrlFields);
            return payload;
        }

        private static int CountScalar(object value)
        {
            return value == null ? 0 : 1;
        }

        private static void AddPayload(OrderedDictionary payload, string name, object value)
        {
            if (value == null) { return; }
            BulkOperationPayload.ValidateSerializableValue(value, name);
            payload.Add(name, value);
        }

        private void SetProperty(string name, object value)
        {
            var property = GetType().GetProperty(name, System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.IgnoreCase);
            property.SetValue(this, value, null);
        }
    }

    public sealed class SubmittedBulkOperation
    {
        public string TaskId { get; set; }

        public SubmittedBulkOperation() { }

        public override string ToString()
        {
            return TaskId ?? string.Empty;
        }
    }

    public sealed class BulkOperationProgress
    {
        public string TaskId { get; set; }
        public BulkOperationStatus? Status { get; set; }
        public int? ProgressPercent { get; set; }
        public User SubmittedBy { get; set; }
        public long? Created { get; set; }
        public long? Started { get; set; }
        public long? Updated { get; set; }
        public long[] ProcessedAccessibleIssues { get; set; }
        public Dictionary<string, string[]> FailedAccessibleIssues { get; set; }
        public int? InvalidOrInaccessibleIssueCount { get; set; }
        public int? TotalIssueCount { get; set; }

        public bool HasPartialFailures
        {
            get
            {
                return (FailedAccessibleIssues != null && FailedAccessibleIssues.Count > 0)
                    || (InvalidOrInaccessibleIssueCount.HasValue && InvalidOrInaccessibleIssueCount.Value > 0);
            }
        }

        public BulkOperationProgress() { }

        public override string ToString()
        {
            if (Status.HasValue && !string.IsNullOrEmpty(TaskId))
            {
                return TaskId + " [" + Status.Value.ToString() + "]";
            }
            return TaskId ?? string.Empty;
        }
    }
}
