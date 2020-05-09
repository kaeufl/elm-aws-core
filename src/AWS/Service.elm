module AWS.Service exposing
    ( Service
    , defineGlobal, defineRegional
    , ApiVersion, Region, Protocol(..), Signer(..), TimestampFormat(..)
    , setJsonVersion, setSigningName, setTargetPrefix, setTimestampFormat, setXmlNamespace, toDigitalOceanSpaces
    , host, endpointPrefix, acceptType, signer, contentType, region, protocol, targetPrefix
    )

{-| AWS service configuration.


# Define a Service.

@docs Service
@docs defineGlobal, defineRegional
@docs ApiVersion, Region, Protocol, Signer, TimestampFormat


# Optional properties that can be added to a Service.

@docs setJsonVersion, setSigningName, setTargetPrefix, setTimestampFormat, setXmlNamespace, toDigitalOceanSpaces


# Internals

@docs host, endpointPrefix, acceptType, signer, contentType, region, protocol, targetPrefix

-}

import Enum exposing (Enum)


{-| Defines an AWS service.
-}
type alias Service =
    { endpointPrefix : String
    , apiVersion : ApiVersion
    , protocol : Protocol
    , signer : Signer
    , jsonVersion : Maybe String
    , signingName : Maybe String
    , targetPrefix : String
    , timestampFormat : TimestampFormat
    , xmlNamespace : Maybe String
    , endpoint : Endpoint
    , hostResolver : Endpoint -> String -> String
    , regionResolver : Endpoint -> String
    }


{-| Creates a global service definition.
-}
defineGlobal : String -> ApiVersion -> Protocol -> Signer -> Service
defineGlobal =
    define


{-| Creates a regional service definition.
-}
defineRegional : String -> ApiVersion -> Protocol -> Signer -> Region -> Service
defineRegional prefix apiVersion proto signerType rgn =
    let
        svc =
            define prefix apiVersion proto signerType
    in
    { svc | endpoint = RegionalEndpoint rgn }


{-| Version of a service.
-}
type alias ApiVersion =
    String


{-| An AWS region string.

For example `"us-east-1"`.

-}
type alias Region =
    String


{-| Defines the different protocols that AWS services can use.
-}
type Protocol
    = EC2
    | JSON
    | QUERY
    | REST_JSON
    | REST_XML


{-| Defines the different signing schemes that AWS services can use.
-}
type Signer
    = SignV4
    | SignS3


{-| Defines an AWS service endpoint.
-}
type Endpoint
    = GlobalEndpoint
    | RegionalEndpoint Region


{-| Defines the different timestamp formats that AWS services can use.
-}
type TimestampFormat
    = ISO8601
    | RFC822
    | UnixTimestamp



-- OPTIONAL SETTERS


{-| Specifies JSON version.
-}
type alias JsonVersion =
    String


{-| Set the JSON apiVersion.

Use this if `jsonVersion` is provided in the metadata.

-}
setJsonVersion : String -> Service -> Service
setJsonVersion jsonVersion service =
    { service | jsonVersion = Just jsonVersion }


{-| Use Digital Ocean Spaces as the backend service provider.

Changes the way hostnames are resolved.

-}
toDigitalOceanSpaces : Service -> Service
toDigitalOceanSpaces service =
    { service
        | hostResolver =
            \endpoint _ ->
                case endpoint of
                    GlobalEndpoint ->
                        "nyc3.digitaloceanspaces.com"

                    RegionalEndpoint rgn ->
                        rgn ++ ".digitaloceanspaces.com"
        , regionResolver =
            \endpoint ->
                case endpoint of
                    GlobalEndpoint ->
                        "nyc3"

                    RegionalEndpoint rgn ->
                        rgn
    }


{-| Set the signing name for the service.

Use this if `signingName` is provided in the metadata.

-}
setSigningName : String -> Service -> Service
setSigningName name service =
    { service | signingName = Just name }


{-| Set the target prefix for the service.

Use this if `targetPrefix` is provided in the metadata.

-}
setTargetPrefix : String -> Service -> Service
setTargetPrefix prefix service =
    { service | targetPrefix = prefix }


{-| Set the timestamp format for the service.

Use this if `timestampFormat` is provided in the metadata.

-}
setTimestampFormat : TimestampFormat -> Service -> Service
setTimestampFormat format service =
    { service | timestampFormat = format }


{-| Set the XML namespace for the service.

Use this if `xmlNamespace` is provided in the metadata.

-}
setXmlNamespace : String -> Service -> Service
setXmlNamespace namespace service =
    { service | xmlNamespace = Just namespace }



-- Move to Internal module.


define :
    String
    -> ApiVersion
    -> Protocol
    -> Signer
    -> Service
define prefix apiVersion proto signerType =
    { endpointPrefix = prefix
    , protocol = proto
    , signer = signerType
    , apiVersion = apiVersion
    , jsonVersion = Nothing
    , signingName = Nothing
    , targetPrefix = defaultTargetPrefix prefix apiVersion
    , timestampFormat = defaultTimestampFormat proto
    , xmlNamespace = Nothing
    , endpoint = GlobalEndpoint
    , hostResolver = defaultHostResolver
    , regionResolver = defaultRegionResolver
    }


{-| Set the target prefix.
-}
targetPrefix : Service -> String
targetPrefix spec =
    spec.targetPrefix


{-| Name of the service.
-}
endpointPrefix : Service -> String
endpointPrefix spec =
    spec.endpointPrefix


{-| Service signature version.
-}
signer : Service -> Signer
signer spec =
    spec.signer


{-| Protocol of the service.
-}
protocol : Service -> Protocol
protocol spec =
    spec.protocol


{-| Gets the service content type header value.
-}
contentType : Service -> String
contentType spec =
    (case spec.protocol of
        REST_XML ->
            "application/xml"

        _ ->
            case spec.jsonVersion of
                Just apiVersion ->
                    "application/x-amz-json-" ++ apiVersion

                Nothing ->
                    "application/json"
    )
        ++ "; charset=utf-8"


{-| Gets the service Accept header value.
-}
acceptType : Service -> String
acceptType spec =
    case spec.protocol of
        REST_XML ->
            "application/xml"

        _ ->
            "application/json"



-- ENDPOINTS


{-| Create a regional endpoint given a region.
-}
regionalEndpoint : Region -> Endpoint
regionalEndpoint =
    RegionalEndpoint


{-| Create a global endpoint.
-}
globalEndpoint : Endpoint
globalEndpoint =
    GlobalEndpoint


{-| Service endpoint as a hostname.
-}
host : Service -> String
host spec =
    spec.hostResolver spec.endpoint spec.endpointPrefix


defaultHostResolver : Endpoint -> String -> String
defaultHostResolver endpoint prefix =
    case endpoint of
        GlobalEndpoint ->
            prefix ++ ".amazonaws.com"

        RegionalEndpoint rgn ->
            prefix ++ "." ++ rgn ++ ".amazonaws.com"


{-| Service region.
-}
region : Service -> String
region { endpoint, regionResolver } =
    regionResolver endpoint


defaultRegionResolver : Endpoint -> String
defaultRegionResolver endpoint =
    case endpoint of
        RegionalEndpoint rgn ->
            rgn

        GlobalEndpoint ->
            -- See http://docs.aws.amazon.com/general/latest/gr/sigv4_changes.html
            "us-east-1"


{-| Use the timestamp format ISO8601.
-}
iso8601 : TimestampFormat
iso8601 =
    ISO8601


{-| Use the timestamp format RCF822.
-}
rfc822 : TimestampFormat
rfc822 =
    RFC822


{-| Use the timestamp format UnixTimestamp.
-}
unixTimestamp : TimestampFormat
unixTimestamp =
    UnixTimestamp



-- HELPERS


defaultTargetPrefix : String -> ApiVersion -> String
defaultTargetPrefix prefix apiVersion =
    "AWS"
        ++ String.toUpper prefix
        ++ "_"
        ++ (apiVersion |> String.split "-" |> String.join "")


{-| See aws-sdk-js

`lib/model/shape.js`: function TimestampShape

-}
defaultTimestampFormat : Protocol -> TimestampFormat
defaultTimestampFormat proto =
    case proto of
        JSON ->
            UnixTimestamp

        REST_JSON ->
            UnixTimestamp

        _ ->
            ISO8601



-- These not needed here. Put them in elm-aws-codegen.


timestampFormatEnum : Enum TimestampFormat
timestampFormatEnum =
    Enum.define
        [ ISO8601
        , RFC822
        , UnixTimestamp
        ]
        (\val ->
            case val of
                ISO8601 ->
                    "iso8601"

                RFC822 ->
                    "rfc822"

                UnixTimestamp ->
                    "unixTimestamp"
        )


protocolEnum : Enum Protocol
protocolEnum =
    Enum.define
        [ EC2
        , JSON
        , QUERY
        , REST_JSON
        , REST_XML
        ]
        (\val ->
            case val of
                EC2 ->
                    "ec2"

                JSON ->
                    "json"

                QUERY ->
                    "query"

                REST_JSON ->
                    "rest-json"

                REST_XML ->
                    "rest-xml"
        )


signerEnum : Enum Signer
signerEnum =
    Enum.define
        [ SignV4
        , SignS3
        ]
        (\val ->
            case val of
                SignV4 ->
                    "v4"

                SignS3 ->
                    "s3"
        )
