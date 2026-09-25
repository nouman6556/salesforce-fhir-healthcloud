%dw 2.0
output application/json
// Transforms an HL7 FHIR R4 Patient resource into a Salesforce Person Account
// payload (Health Cloud). Used in the MuleSoft System API layer.
var officialName = (payload.name default []) filter ($.use == "official") then $[0] default payload.name[0]
var mrn = (payload.identifier default []) filter ($.type.coding[0].code == "MR") then $[0].value
---
{
  FirstName: (officialName.given default [])[0],
  LastName: officialName.family,
  PersonBirthdate: payload.birthDate as Date {format: "yyyy-MM-dd"} default null,
  Gender__pc: upper(payload.gender default "unknown"),
  MRN__pc: mrn,
  FHIR_Patient_Id__pc: payload.id,
  PersonMailingStreet: (payload.address[0].line default []) joinBy " ",
  PersonMailingCity: payload.address[0].city,
  PersonMailingState: payload.address[0].state,
  PersonMailingPostalCode: payload.address[0].postalCode,
  PersonHomePhone: ((payload.telecom default []) filter ($.system == "phone"))[0].value,
  PersonEmail: ((payload.telecom default []) filter ($.system == "email"))[0].value
}
