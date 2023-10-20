---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# GitLab Duo

GitLab is creating AI-assisted features across our DevSecOps platform. These features aim to help increase velocity and solve key pain points across the software development lifecycle.

| Feature | Purpose | Large Language Model | Current availability | Maturity |
|-|-|-|-|-|
| [Suggested Reviewers](project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers) | Assists in creating faster and higher-quality reviews by automatically suggesting reviewers for your merge request. | GitLab creates a machine learning model for each project, which is used to generate reviewers <br><br> [View the issue](https://gitlab.com/gitlab-org/modelops/applied-ml/applied-ml-updates/-/issues/10) | SaaS only <br><br> Ultimate tier | [Generally Available (GA)](../policy/experiment-beta-support.md#generally-available-ga) |
| [Code Suggestions](project/repository/code_suggestions/index.md) | Helps you write code more efficiently by viewing code suggestions as you type. | [`code-gecko`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/code-completion) and [`code-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/code-generation) <br><br> [Anthropic's Claude](https://www.anthropic.com/product) model | SaaS <br> Self-managed <br><br> All tiers | [Beta](../policy/experiment-beta-support.md#beta) |
| [Vulnerability summary](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | Helps you remediate vulnerabilities more efficiently, uplevel your skills, and write more secure code. | [`text-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text) <br><br> Anthropic's claude model if degraded performance | SaaS only <br><br> Ultimate tier | [Beta](../policy/experiment-beta-support.md#beta) |
| [Code explanation](#explain-code-in-the-web-ui-with-code-explanation) | Helps you understand code by explaining it in English language. | [`codechat-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/code-chat) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [GitLab Duo Chat](gitlab_duo_chat.md) | Process and generate text and code in a conversational manner. Helps you quickly identify useful information in large volumes of text in issues, epics, code, and GitLab documentation. | Anthropic's claude model <br><br> OpenAI Embeddings | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Value stream forecasting](#forecast-deployment-frequency-with-value-stream-forecasting) | Assists you with predicting productivity metrics and identifying anomalies across your software development lifecycle. | Statistical forecasting | SaaS only <br> Self-managed <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Discussion summary](#summarize-issue-discussions-with-discussion-summary) | Assists with quickly getting everyone up to speed on lengthy conversations to help ensure you are all on the same page. | OpenAI's GPT-3 | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Merge request summary](project/merge_requests/ai_in_merge_requests.md#summarize-merge-request-changes) | Efficiently communicate the impact of your merge request changes. | [`text-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Code review summary](project/merge_requests/ai_in_merge_requests.md#summarize-my-merge-request-review) | Helps ease merge request handoff between authors and reviewers and help reviewers efficiently understand suggestions. | [`text-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Merge request template population](project/merge_requests/ai_in_merge_requests.md#fill-in-merge-request-templates) | Generate a description for the merge request based on the contents of the template. | [`text-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Test generation](project/merge_requests/ai_in_merge_requests.md#generate-suggested-tests-in-merge-requests) | Automates repetitive tasks and helps catch bugs early. | [`text-bison`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Git suggestions](https://gitlab.com/gitlab-org/gitlab/-/issues/409636) | Helps you discover or recall Git commands when and where you need them. | [Google Vertex Codey APIs](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Root cause analysis](#root-cause-analysis) | Assists you in determining the root cause for a pipeline failure and failed CI/CD build. | [Google Vertex Codey APIs](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview) | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |
| [Issue description generation](#summarize-an-issue-with-issue-description-generation) | Generate issue descriptions. | OpenAI's GPT-3 | SaaS only <br><br> Ultimate tier | [Experiment](../policy/experiment-beta-support.md#experiment) |

## Enable AI/ML features

- Third-party AI features
  - All features built on large language models (LLM) from Google,
    Anthropic or OpenAI (besides Code Suggestions) require that this setting is
    enabled at the group level.
  - [Generally Available](../policy/experiment-beta-support.md#generally-available-ga)
    features are available when third-party AI features are enabled.
  - Third-party AI features are enabled by default.
  - This setting is available to Ultimate groups on SaaS and can be
    set by a user who has the Owner role in the group.
  - View [how to enable this setting](group/manage.md#enable-third-party-ai-features).
- Experiment and Beta features
  - All features categorized as
    [Experiment features](../policy/experiment-beta-support.md#experiment) or
    [Beta features](../policy/experiment-beta-support.md#beta)
    (besides Code Suggestions) require that this setting is enabled at the group
    level. This is in addition to the Third-party AI features setting.
  - Their usage is subject to the
    [Testing Terms of Use](https://about.gitlab.com/handbook/legal/testing-agreement/).
  - Experiment and Beta features are disabled by default.
  - This setting is available to Ultimate groups on SaaS and can be set by a user
    who has the Owner role in the group.
  - View [how to enable this setting](group/manage.md#enable-experiment-and-beta-features).
- Code Suggestions
  - View [how to enable for self-managed](project/repository/code_suggestions/self_managed.md#enable-code-suggestions-on-self-managed-gitlab).
  - View [how to enable for SaaS](project/repository/code_suggestions/saas.md#enable-code-suggestions).

## Experimental AI features and how to use them

The following subsections describe the experimental AI features in more detail.

### Explain code in the Web UI with Code explanation **(ULTIMATE SAAS EXPERIMENT)**

> Introduced in GitLab 15.11 as an [Experiment](../policy/experiment-beta-support.md#experiment) on GitLab.com.

To use this feature:

- The parent group of the project must:
  - Enable the [third-party AI features setting](group/manage.md#enable-third-party-ai-features).
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must be a member of the project with sufficient permissions to view the repository.

GitLab can help you get up to speed faster if you:

- Spend a lot of time trying to understand pieces of code that others have created, or
- Struggle to understand code written in a language that you are not familiar with.

By using a large language model, GitLab can explain the code in natural language.

To explain your code:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select any file in your project that contains code.
1. On the file, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

You can also have code explained in the context of a merge request. To explain
code in a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Code > Merge requests**, then select your merge request.
1. On the secondary menu, select **Changes**.
1. On the file you would like explained, select the three dots (**{ellipsis_v}**) and select **View File @ $SHA**.

   A separate browser tab opens and shows the full file with the latest changes.

1. On the new tab, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

![How to use the Explain Code Experiment](img/explain_code_experiment.png)

We cannot guarantee that the large language model produces results that are correct. Use the explanation with caution.

### Summarize issue discussions with Discussion summary **(ULTIMATE SAAS EXPERIMENT)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10344) in GitLab 16.0 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the issue must:
  - Enable the [third-party AI features setting](group/manage.md#enable-third-party-ai-features).
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must be a member of the project with sufficient permissions to view the issue.

You can generate a summary of discussions on an issue:

1. In an issue, scroll to the **Activity** section.
1. Select **View summary**.

The comments in the issue are summarized in as many as 10 list items.
The summary is displayed only for you.

Provide feedback on this experimental feature in [issue 407779](https://gitlab.com/gitlab-org/gitlab/-/issues/407779).

**Data usage**: When you use this feature, the text of public comments on the issue are sent to the large
language model referenced above.

### Forecast deployment frequency with Value stream forecasting **(ULTIMATE ALL EXPERIMENT)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10228) in GitLab 16.2 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [third-party AI features setting](group/manage.md#enable-third-party-ai-features).
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must be a member of the project with sufficient permissions to view the CI/CD analytics.

In CI/CD Analytics, you can view a forecast of deployment frequency:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > CI/CD analytics**.
1. Select the **Deployment frequency** tab.
1. Turn on the **Show forecast** toggle.
1. On the confirmation dialog, select **Accept testing terms**.

The forecast is displayed as a dotted line on the chart. Data is forecasted for a duration that is half of the selected date range.
For example, if you select a 30-day range, a forecast for the following 15 days is displayed.

![Forecast deployment frequency](img/forecast_deployment_frequency.png)

Provide feedback on this experimental feature in [issue 416833](https://gitlab.com/gitlab-org/gitlab/-/issues/416833).

### Root cause analysis **(ULTIMATE SAAS EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692) in GitLab 16.2 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [third-party AI features setting](group/manage.md#enable-third-party-ai-features).
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must be a member of the project with sufficient permissions to view the CI/CD job.

When the feature is available, the "Root cause analysis" button will appears on
a failed CI/CD job. Selecting this button generates an analysis regarding the
reason for the failure.

### Summarize an issue with Issue description generation **(ULTIMATE SAAS EXPERIMENT)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10762) in GitLab 16.3 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [third-party AI features setting](group/manage.md#enable-third-party-ai-features).
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must be a member of the project with sufficient permissions to view the issue.

You can generate the description for an issue from a short summary.

1. Create a new issue.
1. Above the **Description** field, select **AI actions > Generate issue description**.
1. Write a short description and select **Submit**.

The issue description is replaced with AI-generated text.

Provide feedback on this experimental feature in [issue 409844](https://gitlab.com/gitlab-org/gitlab/-/issues/409844).

**Data usage**: When you use this feature, the text you enter is sent to the large
language model referenced above.

### GitLab Duo Chat **(ULTIMATE SAAS EXPERIMENT)**

For details about this Experimental feature, see [GitLab Duo Chat](gitlab_duo_chat.md).

## Data usage

GitLab AI features leverage generative AI to help increase velocity and aim to help make you more productive. Each feature operates independently of other features and is not required for other features to function.

### Progressive enhancement

These features are designed as a progressive enhancement to existing GitLab features across our DevSecOps platform. They are designed to fail gracefully and should not prevent the core functionality of the underlying feature. You should note each feature is subject to its expected functionality as defined by the relevant [feature support policy](../policy/experiment-beta-support.md).

### Stability and performance

These features are in a variety of [feature support levels](../policy/experiment-beta-support.md#beta). Due to the nature of these features, there may be high demand for usage which may cause degraded performance or unexpected downtime of the feature. We have built these features to gracefully degrade and have controls in place to allow us to mitigate abuse or misuse. GitLab may disable **beta and experimental** features for any or all customers at any time at our discretion.

## Third party services

### Data privacy

Some AI features require the use of third-party AI services models and APIs from: Google AI and OpenAI. The processing of any personal data is in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/). You may also visit the [Sub-Processors page](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors) to see the list of our Sub-Processors that we use to provide these features.

Group owners can control which top-level groups have access to third-party AI features by using the [group level third-party AI features setting](group/manage.md#enable-third-party-ai-features).

### Model accuracy and quality

Generative AI may produce unexpected results that may be:

- Low-quality
- Incoherent
- Incomplete
- Produce failed pipelines
- Insecure code
- Offensive or insensitive
- Out of date information

GitLab is actively iterating on all our AI-assisted capabilities to improve the quality of the generated content. We improve the quality through prompt engineering, evaluating new AI/ML models to power these features, and through novel heuristics built into these features directly.
