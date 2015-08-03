{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE PackageImports             #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE ViewPatterns               #-}

-- |
-- Module      : Network.AWS.Types
-- Copyright   : (c) 2013-2015 Brendan Hay
-- License     : Mozilla Public License, v. 2.0.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)
--
module Network.AWS.Types
    (
    -- * Authentication
    -- ** Credentials
      AccessKey       (..)
    , SecretKey       (..)
    , SecurityToken   (..)
    -- ** Environment
    , AuthEnv         (..)
    , Auth            (..)
    , withAuth

    -- * Services
    , Abbrev
    , AWSService      (..)
    , Service         (..)
    , serviceOf

    -- * Retries
    , Retry           (..)

    -- * Signing
    , AWSSigner       (..)
    , AWSPresigner    (..)
    , Meta
    , Signed          (..)
    , sgMeta
    , sgRequest

    -- * Requests
    , AWSRequest      (..)
    , Request         (..)
    , rqMethod
    , rqHeaders
    , rqPath
    , rqQuery
    , rqBody

    -- * Responses
    , Response

    -- * Errors
    , AWSError        (..)
    , Error           (..)
    -- ** HTTP Errors
    , HttpException
    -- ** Serialize Errors
    , SerializeError  (..)
    , serializeAbbrev
    , serializeStatus
    , serializeMessage
    -- ** Service Errors
    , ServiceError    (..)
    , serviceAbbrev
    , serviceStatus
    , serviceHeaders
    , serviceCode
    , serviceMessage
    , serviceRequestId
    -- ** Error Types
    , ErrorCode       (..)
    , ErrorMessage    (..)
    , RequestId       (..)

    -- * Regions
    , Endpoint        (..)
    , Region          (..)

    -- * HTTP
    , ClientRequest
    , ClientResponse
    , ResponseBody
    , clientRequest

    -- ** Seconds
    , Seconds         (..)
    , _Seconds
    , microseconds

    -- * Isomorphisms
    , _Coerce
    , _Default
    ) where

import           Control.Exception
import           Control.Exception.Lens       (exception)
import           Control.Applicative
import           Control.Concurrent           (ThreadId)
import           Control.Lens                 hiding (coerce)
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Resource
import           Data.Aeson                   hiding (Error)
import           Data.ByteString.Builder      (Builder)
import qualified Data.ByteString.Builder      as Build
import qualified Data.ByteString.Lazy.Char8   as LBS8
import           Data.Coerce
import           Data.Conduit
import           Data.Data                    (Data, Typeable)
import           Data.Hashable
import           Data.IORef
import           Data.Monoid
import           Data.Proxy
import           Data.String
import qualified Data.Text.Encoding           as Text
import           Data.Time
import           GHC.Generics                 (Generic)
import           Network.AWS.Data.Body
import           Network.AWS.Data.ByteString
import           Network.AWS.Data.Path
import           Network.AWS.Data.Query
import           Network.AWS.Data.Text
import           Network.AWS.Data.XML
import           Network.AWS.Logger
import           Network.HTTP.Client          hiding (Request, Response, Proxy)
import qualified Network.HTTP.Client          as Client
import           Network.HTTP.Types.Header
import           Network.HTTP.Types.Method
import           Network.HTTP.Types.Status    (Status)
import           Text.XML                     (def)

-- | A convenience alias to avoid type ambiguity.
type ClientRequest = Client.Request

-- | A convenience alias encapsulating the common 'Response'.
type ClientResponse = Client.Response ResponseBody

-- | A convenience alias encapsulating the common 'Response' body.
type ResponseBody = ResumableSource (ResourceT IO) ByteString

-- | Construct a 'ClientRequest' using common parameters such as TLS and prevent
-- throwing errors when receiving erroneous status codes in respones.
clientRequest :: ClientRequest
clientRequest = def
    { Client.secure        = True
    , Client.port          = 443
    , Client.redirectCount = 0
    , Client.checkStatus   = \_ _ _ -> Nothing
    }

-- | Abbreviated service name.
newtype Abbrev = Abbrev Text
    deriving (Eq, Ord, Show, IsString, FromXML, FromJSON, FromText, ToText, ToLog)

newtype ErrorCode = ErrorCode Text
    deriving (Eq, Ord, Show, IsString, FromXML, FromJSON, FromText, ToText, ToLog)

newtype ErrorMessage = ErrorMessage Text
    deriving (Eq, Ord, Show, IsString, FromXML, FromJSON, FromText, ToText, ToLog)

newtype RequestId = RequestId Text
    deriving (Eq, Ord, Show, IsString, FromXML, FromJSON, FromText, ToText, ToLog)

-- | An error type representing errors that can be attributed to this library.
data Error
    = HTTPError      HttpException
    | SerializeError SerializeError
    | ServiceError   ServiceError
      deriving (Show, Typeable)

instance Exception Error

instance ToLog Error where
    message = \case
        HTTPError      e -> message e
        SerializeError e -> message e
        ServiceError   e -> message e

data SerializeError = SerializeError'
    { _serializeAbbrev  :: !Abbrev
    , _serializeStatus  :: !Status
    , _serializeMessage :: String
    } deriving (Eq, Show, Typeable)

instance ToLog SerializeError where
    message SerializeError'{..} = buildLines
        [ "[SerializeError] {"
        , "  service = " <> message _serializeAbbrev
        , "  status  = " <> message _serializeStatus
        , "  message = " <> message _serializeMessage
        , "}"
        ]

serializeAbbrev :: Lens' SerializeError Abbrev
serializeAbbrev = lens _serializeAbbrev (\s a -> s { _serializeAbbrev = a })

serializeStatus :: Lens' SerializeError Status
serializeStatus = lens _serializeStatus (\s a -> s { _serializeStatus = a })

serializeMessage :: Lens' SerializeError String
serializeMessage = lens _serializeMessage (\s a -> s { _serializeMessage = a })

data ServiceError = ServiceError'
    { _serviceAbbrev    :: !Abbrev
    , _serviceStatus    :: !Status
    , _serviceHeaders   :: [Header]
    , _serviceCode      :: !ErrorCode
    , _serviceMessage   :: Maybe ErrorMessage
    , _serviceRequestId :: Maybe RequestId
    } deriving (Eq, Show, Typeable)

instance ToLog ServiceError where
    message ServiceError'{..} = buildLines
        [ "[ServiceError] {"
        , "  service    = " <> message _serviceAbbrev
        , "  status     = " <> message _serviceStatus
        , "  code       = " <> message _serviceCode
        , "  message    = " <> message _serviceMessage
        , "  request-id = " <> message _serviceRequestId
        , "}"
        ]

serviceAbbrev :: Lens' ServiceError Abbrev
serviceAbbrev = lens _serviceAbbrev (\s a -> s { _serviceAbbrev = a })

serviceStatus :: Lens' ServiceError Status
serviceStatus = lens _serviceStatus (\s a -> s { _serviceStatus = a })

serviceHeaders :: Lens' ServiceError [Header]
serviceHeaders = lens _serviceHeaders (\s a -> s { _serviceHeaders = a })

serviceCode :: Lens' ServiceError ErrorCode
serviceCode = lens _serviceCode (\s a -> s { _serviceCode = a })

serviceMessage :: Lens' ServiceError (Maybe ErrorMessage)
serviceMessage = lens _serviceMessage (\s a -> s { _serviceMessage = a })

serviceRequestId :: Lens' ServiceError (Maybe RequestId)
serviceRequestId = lens _serviceRequestId (\s a -> s { _serviceRequestId = a })

class AWSError a where
    _Error          :: Prism' a Error
    _HTTPError      :: Prism' a HttpException
    _SerializeError :: Prism' a SerializeError
    _ServiceError   :: Prism' a ServiceError

    _HTTPError      = _Error . _HTTPError
    _SerializeError = _Error . _SerializeError
    _ServiceError   = _Error . _ServiceError

instance AWSError SomeException where
    _Error = exception

instance AWSError Error where
    _Error = id

    _HTTPError = prism HTTPError $ \case
        HTTPError e -> Right e
        x           -> Left x

    _SerializeError = prism SerializeError $ \case
        SerializeError e -> Right e
        x                -> Left  x

    _ServiceError = prism ServiceError $ \case
        ServiceError e -> Right e
        x              -> Left  x

data Endpoint = Endpoint
    { _endpointHost  :: ByteString
    , _endpointScope :: ByteString
    } deriving (Eq, Show, Data, Typeable)

-- | Constants and predicates used to create a 'RetryPolicy'.
data Retry = Exponential
    { _retryBase     :: !Double
    , _retryGrowth   :: !Int
    , _retryAttempts :: !Int
    , _retryCheck    :: ServiceError -> Maybe Text
      -- ^ Returns a descriptive name for logging
      -- if the request should be retried.
    }

-- | Attributes and functions specific to an AWS service.
data Service s = Service
    { _svcAbbrev   :: !Abbrev
    , _svcPrefix   :: ByteString
    , _svcVersion  :: ByteString
    , _svcEndpoint :: Region -> Endpoint
    , _svcTimeout  :: Maybe Seconds
    , _svcStatus   :: Status -> Bool
    , _svcError    :: Abbrev -> Status -> [Header] -> LazyByteString -> Error
    , _svcRetry    :: Retry
    }

-- | An unsigned request.
data Request a = Request
    { _rqMethod    :: !StdMethod
    , _rqPath      :: !RawPath
    , _rqQuery     :: !QueryString
    , _rqHeaders   :: ![Header]
    , _rqBody      :: !RqBody
    }

instance Show (Request a) where
    show = LBS8.unpack . Build.toLazyByteString . message

instance ToLog (Request a) where
    message Request{..} = buildLines
        [ "[Raw Request] {"
        , "  method    = "  <> message _rqMethod
        , "  path      = "  <> message (escapePath _rqPath)
        , "  query     = "  <> message _rqQuery
        , "  headers   = "  <> message _rqHeaders
        , "  body      = {"
        , "    hash    = "  <> message (toBS (bodySHA256  _rqBody))
        , "    payload =\n" <> message (bodyRequest _rqBody)
        , "  }"
        , "}"
        ]

rqBody :: Lens' (Request a) RqBody
rqBody = lens _rqBody (\s a -> s { _rqBody = a })

rqHeaders :: Lens' (Request a) [Header]
rqHeaders = lens _rqHeaders (\s a -> s { _rqHeaders = a })

rqMethod :: Lens' (Request a) StdMethod
rqMethod = lens _rqMethod (\s a -> s { _rqMethod = a })

rqPath :: Lens' (Request a) RawPath
rqPath = lens _rqPath (\s a -> s { _rqPath = a })

rqQuery :: Lens' (Request a) QueryString
rqQuery = lens _rqQuery (\s a -> s { _rqQuery = a })

class AWSSigner v where
    signed :: v ~ Sg s
           => AuthEnv
           -> Region
           -> UTCTime
           -> Service s
           -> Request a
           -> Signed  v a

class AWSPresigner v where
    presigned :: v ~ Sg s
              => AuthEnv
              -> Region
              -> UTCTime
              -> Integer
              -> Service s
              -> Request a
              -> Signed  v a

-- | Signing metadata data specific to a signing algorithm.
--
-- /Note:/ this is used for logging purposes, and is otherwise ignored.
data family Meta v :: *

-- | A signed 'ClientRequest' and associated metadata specific to the signing
-- algorithm that was used.
data Signed v a where
    Signed :: ToLog (Meta v)
           => { _sgMeta    :: Meta v
              , _sgRequest :: ClientRequest
              }
           -> Signed v a

sgMeta :: ToLog (Meta v) => Lens' (Signed v a) (Meta v)
sgMeta f (Signed m rq) = f m <&> \y -> Signed y rq

-- Lens' specifically since 'a' cannot be substituted.
sgRequest :: Lens' (Signed v a) ClientRequest
sgRequest f (Signed m rq) = f rq <&> \y -> Signed m y

class AWSSigner (Sg a) => AWSService a where
    -- | The default signing algorithm for the service.
    type Sg a :: *

    service :: Sv p ~ a => Proxy p -> Service a

serviceOf :: forall a. AWSService (Sv a) => a -> Service (Sv a)
serviceOf = const $ service (Proxy :: Proxy a)

type Response a = (Status, Rs a)

-- | Specify how a request can be de/serialised.
class AWSService (Sv a) => AWSRequest a where
    -- | The successful, expected response associated with a request.
    type Rs a :: *

    -- | The default sevice configuration for the request.
    type Sv a :: *

    request  :: a -> Request a
    response :: MonadResource m
             => Logger
             -> Service s
             -> Request a
             -> ClientResponse
             -> m (Response a)

-- | Access key credential.
newtype AccessKey = AccessKey ByteString
    deriving (Eq, Show, IsString, ToText, ToByteString, ToLog)

-- | Secret key credential.
newtype SecretKey = SecretKey ByteString
    deriving (Eq, IsString, ToText, ToByteString)

-- | A security token used by STS to temporarily authorise access to
-- an AWS resource.
newtype SecurityToken = SecurityToken ByteString
    deriving (Eq, IsString, ToText, ToByteString)

-- | The authorisation environment.
data AuthEnv = AuthEnv
    { _authAccess :: !AccessKey
    , _authSecret :: !SecretKey
    , _authToken  :: Maybe SecurityToken
    , _authExpiry :: Maybe UTCTime
    }

instance ToLog AuthEnv where
    message AuthEnv{..} = buildLines
        [ "[Amazonka Auth] {"
        , "  access key     = ****"
        , "  secret key     = ****"
        , "  security token = " <> message (const "****" <$> _authToken :: Maybe Builder)
        , "  expiry         = " <> message _authExpiry
        , "}"
        ]

instance FromJSON AuthEnv where
    parseJSON = withObject "AuthEnv" $ \o -> AuthEnv
        <$> f AccessKey (o .: "AccessKeyId")
        <*> f SecretKey (o .: "SecretAccessKey")
        <*> fmap (f SecurityToken) (o .:? "Token")
        <*> o .:? "Expiration"
      where
        f g = fmap (g . Text.encodeUtf8)

-- | An authorisation environment containing AWS credentials, and potentially
-- a reference which can be refreshed out-of-band as temporary credentials expire.
data Auth
    = Ref  ThreadId (IORef AuthEnv)
    | Auth AuthEnv

instance ToLog Auth where
    message (Ref t _) = "[Amazonka Auth] { <thread:" <> message (show t) <> "> }"
    message (Auth  e) = message e

withAuth :: MonadIO m => Auth -> (AuthEnv -> m a) -> m a
withAuth (Ref _ r) f = liftIO (readIORef r) >>= f
withAuth (Auth  e) f = f e

-- | The sum of available AWS regions.
data Region
    = Ireland         -- ^ Europe / eu-west-1
    | Frankfurt       -- ^ Europe / eu-central-1
    | Tokyo           -- ^ Asia Pacific / ap-northeast-1
    | Singapore       -- ^ Asia Pacific / ap-southeast-1
    | Sydney          -- ^ Asia Pacific / ap-southeast-2
    | Beijing         -- ^ China / cn-north-1
    | NorthVirginia   -- ^ US / us-east-1
    | NorthCalifornia -- ^ US / us-west-1
    | Oregon          -- ^ US / us-west-2
    | GovCloud        -- ^ AWS GovCloud / us-gov-west-1
    | GovCloudFIPS    -- ^ AWS GovCloud (FIPS 140-2) S3 Only / fips-us-gov-west-1
    | SaoPaulo        -- ^ South America / sa-east-1
      deriving (Eq, Ord, Read, Show, Data, Typeable, Generic)

instance Hashable Region

instance FromText Region where
    parser = takeLowerText >>= \case
        "eu-west-1"          -> pure Ireland
        "eu-central-1"       -> pure Frankfurt
        "ap-northeast-1"     -> pure Tokyo
        "ap-southeast-1"     -> pure Singapore
        "ap-southeast-2"     -> pure Sydney
        "cn-north-1"         -> pure Beijing
        "us-east-1"          -> pure NorthVirginia
        "us-west-2"          -> pure Oregon
        "us-west-1"          -> pure NorthCalifornia
        "us-gov-west-1"      -> pure GovCloud
        "fips-us-gov-west-1" -> pure GovCloudFIPS
        "sa-east-1"          -> pure SaoPaulo
        e                    -> fail $
            "Failure parsing Region from " ++ show e

instance ToText Region where
    toText = \case
        Ireland         -> "eu-west-1"
        Frankfurt       -> "eu-central-1"
        Tokyo           -> "ap-northeast-1"
        Singapore       -> "ap-southeast-1"
        Sydney          -> "ap-southeast-2"
        Beijing         -> "cn-north-1"
        NorthVirginia   -> "us-east-1"
        NorthCalifornia -> "us-west-1"
        Oregon          -> "us-west-2"
        GovCloud        -> "us-gov-west-1"
        GovCloudFIPS    -> "fips-us-gov-west-1"
        SaoPaulo        -> "sa-east-1"

instance ToByteString Region

instance ToLog Region where
    message = message . toBS

instance FromXML Region where parseXML = parseXMLText "Region"
instance ToXML   Region where toXML    = toXMLText

-- | An integral value representing seconds.
newtype Seconds = Seconds Int
    deriving (Eq, Ord, Read, Show, Enum, Num, Bounded, Integral, Real, Data, Typeable, Generic)

_Seconds :: Iso' Seconds Int
_Seconds = iso (\(Seconds n) -> n) Seconds

instance ToLog Seconds where
    message (Seconds n) = message n <> "s"

microseconds :: Seconds -> Int
microseconds (Seconds n) = n * 1000000

_Coerce :: (Coercible a b, Coercible b a) => Iso' a b
_Coerce = iso coerce coerce

-- | Invalid Iso, should be a Prism but exists for ease of composition
-- with the current 'Lens . Iso' chaining to hide internal types from the user.
_Default :: Monoid a => Iso' (Maybe a) a
_Default = iso f Just
  where
    f (Just x) = x
    f Nothing  = mempty
