select concat('company;', sub.company, ';activity,authors,issues,prs,commits,review_comments,issue_comments,commit_comments,comments'),
  sub.activity,
  sub.authors,
  sub.issues,
  sub.prs,
  sub.commits,
  sub.review_comments,
  sub.issue_comments,
  sub.commit_comments,
  sub.review_comments + sub.issue_comments + sub.commit_comments as comments
from (
  select
    affs.company_name as company,
    count(distinct ev.id) as activity,
    count(distinct ev.actor_id) as authors,
    sum(case ev.type when 'IssuesEvent' then 1 else 0 end) as issues,
    sum(case ev.type when 'PullRequestEvent' then 1 else 0 end) as prs,
    sum(case ev.type when 'PushEvent' then 1 else 0 end) as commits,
    sum(case ev.type when 'PullRequestReviewCommentEvent' then 1 else 0 end) as review_comments,
    sum(case ev.type when 'IssueCommentEvent' then 1 else 0 end) as issue_comments,
    sum(case ev.type when 'CommitCommentEvent' then 1 else 0 end) as commit_comments
  from
    gha_events ev,
    gha_actors_affiliations affs
  where
    ev.actor_id = affs.actor_id
    and affs.dt_from <= ev.created_at
    and affs.dt_to > ev.created_at
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and ev.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and ev.dup_actor_login not in (
      'googlebot', 'k8s-ci-robot', 'k8s-merge-robot', 'k8s-bot',
      'k8s-teamcity-mesosphere', 'k8s-reviewable', 'k8s-cherrypick-bot',
      'k8s-publish-robot'
    )
  group by
    affs.company_name
  order by
    authors desc,
    activity desc,
    company asc
  ) sub
where
  sub.authors > 1
  and sub.issues > 0
  and sub.prs > 0
  and sub.commits > 0
  and sub.review_comments + sub.issue_comments > 0
;
