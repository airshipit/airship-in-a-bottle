# UCP API conventions
A collection of conventions that components of the UnderCloud Platform (UCP)
utilize for their REST APIs
---
## Resource path naming
* Resource paths nodes follow an all lower case naming scheme, and pluralize
the resource names. Nodes that refer to keys, ids or names that are externally
controlled, the external naming will be honored.
* The version of the API resource path will be prefixed before the first node
of the path for that resource using v#.# format.
* By default, the API will be namespaced by /api before the version. For the
purposes of documentation, this will not be specified in each of the resource
paths below. In more complex APIs, it makes sense to allow the /api node to be
more specific to point to a particular service.
```
/api/v1.0/sampleresources/ExTeRnAlNAME-1234
      ^         ^       ^       ^
      |         |       |      defer to external naming
      |         |      plural
      |        lower case
     version here
```
---
## Error responses
Error responses (HTTP response body accompanying 4xx and 5xx series responses
where possible) are a more specific version of the
[Kubernetes standard for error representation](https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#response-status-kind).
UCP utilizes the details field in a more formalized way to represent multiple
messages related to an error response, as follows:

```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "{{UCP Component Name}} {{error phrase}}",
  "reason": "{{appropriate reason phrase}}",
  "details": {
    "errorCount": {{n}},
    "errorList": [
       { "message" : "{{validation failure message}}"},
       ...
    ]
  },
  "code": {{http status code}}
}
```

such that:
1. the details field is still optional
2. if used, the details follow that format
3. the repeating entity inside the errorList can be decorated with as many
other fields as are useful, but at least have a message field
---
## Headers
### Required

* X-Auth-Token  
The auth token to identify the invoking user.

### Optional

* X-Context-Marker  
A context id that will be carried on all logs for this client-provided marker.
This marker may only be a 36-character canonical representation of an UUID
(8-4-4-4-12)

## Validation API  
All UCP components that participate in validation of the design supplied to a
site implement a common resource to perform document validations. Document
validations are syncrhonous and target completion in 30 seconds or less.
Because of the different sources of documents that should be supported, a
flexible input descriptor is used to indicate from where a UCP component will
retrieve the documents to be validated.
  
### POST /v1.0/validatedesign  
Invokes a UCP component to perform validations against the documents specified
by the input structure.  Synchronous.

#### Input structure  
```
{
  rel : "design",
  href: "deckhand+https://deckhand/{{revision_id}}/rendered-documents",
  type: "application/x-yaml"
}
```
#### Output structure
The output structure reuses the Kubernetes Status kind to represent the result
of validations. The Status kind will be returned for both successful and failed
validation to maintain a consistent of interface. If there are additional
diagnostics that associate to a particular validation, the entry in the error
list may carry fields other than "message".

Failure message example:
```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Invalid",
  "message": "{{UCP Component Name}} validations failed",
  "reason": "Validation",
  "details": {
    "errorCount": {{n}},
    "errorList": [
       { "message" : "{{validation failure message}}"},
       ...
    ]
  },
  "code": 400
}
```

Success message example:
```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Valid",
  "message": "{{UCP Component Name}} validations succeeded",
  "reason": "Validation",
  "details": {
    "errorCount": 0,
    "errorList": []
  },
  "code": 200
}
```
