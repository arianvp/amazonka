{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE TypeFamilies       #-}

{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-binds   #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-- Derived from AWS service descriptions, licensed under Apache 2.0.

-- |
-- Module      : Network.AWS.WAF.GetSqlInjectionMatchSet
-- Copyright   : (c) 2013-2015 Brendan Hay
-- License     : Mozilla Public License, v. 2.0.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : auto-generated
-- Portability : non-portable (GHC extensions)
--
-- Returns the SqlInjectionMatchSet that is specified by
-- 'SqlInjectionMatchSetId'.
--
-- /See:/ <http://docs.aws.amazon.com/waf/latest/APIReference/API_GetSqlInjectionMatchSet.html AWS API Reference> for GetSqlInjectionMatchSet.
module Network.AWS.WAF.GetSqlInjectionMatchSet
    (
    -- * Creating a Request
      getSqlInjectionMatchSet
    , GetSqlInjectionMatchSet
    -- * Request Lenses
    , gsimsSqlInjectionMatchSetId

    -- * Destructuring the Response
    , getSqlInjectionMatchSetResponse
    , GetSqlInjectionMatchSetResponse
    -- * Response Lenses
    , gsimsrsSqlInjectionMatchSet
    , gsimsrsResponseStatus
    ) where

import           Network.AWS.Lens
import           Network.AWS.Prelude
import           Network.AWS.Request
import           Network.AWS.Response
import           Network.AWS.WAF.Types
import           Network.AWS.WAF.Types.Product

-- | A request to get a SqlInjectionMatchSet.
--
-- /See:/ 'getSqlInjectionMatchSet' smart constructor.
newtype GetSqlInjectionMatchSet = GetSqlInjectionMatchSet'
    { _gsimsSqlInjectionMatchSetId :: Text
    } deriving (Eq,Read,Show,Data,Typeable,Generic)

-- | Creates a value of 'GetSqlInjectionMatchSet' with the minimum fields required to make a request.
--
-- Use one of the following lenses to modify other fields as desired:
--
-- * 'gsimsSqlInjectionMatchSetId'
getSqlInjectionMatchSet
    :: Text -- ^ 'gsimsSqlInjectionMatchSetId'
    -> GetSqlInjectionMatchSet
getSqlInjectionMatchSet pSqlInjectionMatchSetId_ =
    GetSqlInjectionMatchSet'
    { _gsimsSqlInjectionMatchSetId = pSqlInjectionMatchSetId_
    }

-- | The 'SqlInjectionMatchSetId' of the SqlInjectionMatchSet that you want
-- to get. 'SqlInjectionMatchSetId' is returned by
-- CreateSqlInjectionMatchSet and by ListSqlInjectionMatchSets.
gsimsSqlInjectionMatchSetId :: Lens' GetSqlInjectionMatchSet Text
gsimsSqlInjectionMatchSetId = lens _gsimsSqlInjectionMatchSetId (\ s a -> s{_gsimsSqlInjectionMatchSetId = a});

instance AWSRequest GetSqlInjectionMatchSet where
        type Rs GetSqlInjectionMatchSet =
             GetSqlInjectionMatchSetResponse
        request = postJSON wAF
        response
          = receiveJSON
              (\ s h x ->
                 GetSqlInjectionMatchSetResponse' <$>
                   (x .?> "SqlInjectionMatchSet") <*>
                     (pure (fromEnum s)))

instance ToHeaders GetSqlInjectionMatchSet where
        toHeaders
          = const
              (mconcat
                 ["X-Amz-Target" =#
                    ("AWSWAF_20150824.GetSqlInjectionMatchSet" ::
                       ByteString),
                  "Content-Type" =#
                    ("application/x-amz-json-1.1" :: ByteString)])

instance ToJSON GetSqlInjectionMatchSet where
        toJSON GetSqlInjectionMatchSet'{..}
          = object
              (catMaybes
                 [Just
                    ("SqlInjectionMatchSetId" .=
                       _gsimsSqlInjectionMatchSetId)])

instance ToPath GetSqlInjectionMatchSet where
        toPath = const "/"

instance ToQuery GetSqlInjectionMatchSet where
        toQuery = const mempty

-- | The response to a GetSqlInjectionMatchSet request.
--
-- /See:/ 'getSqlInjectionMatchSetResponse' smart constructor.
data GetSqlInjectionMatchSetResponse = GetSqlInjectionMatchSetResponse'
    { _gsimsrsSqlInjectionMatchSet :: !(Maybe SqlInjectionMatchSet)
    , _gsimsrsResponseStatus       :: !Int
    } deriving (Eq,Read,Show,Data,Typeable,Generic)

-- | Creates a value of 'GetSqlInjectionMatchSetResponse' with the minimum fields required to make a request.
--
-- Use one of the following lenses to modify other fields as desired:
--
-- * 'gsimsrsSqlInjectionMatchSet'
--
-- * 'gsimsrsResponseStatus'
getSqlInjectionMatchSetResponse
    :: Int -- ^ 'gsimsrsResponseStatus'
    -> GetSqlInjectionMatchSetResponse
getSqlInjectionMatchSetResponse pResponseStatus_ =
    GetSqlInjectionMatchSetResponse'
    { _gsimsrsSqlInjectionMatchSet = Nothing
    , _gsimsrsResponseStatus = pResponseStatus_
    }

-- | Information about the SqlInjectionMatchSet that you specified in the
-- 'GetSqlInjectionMatchSet' request. For more information, see the
-- following topics:
--
-- -   SqlInjectionMatchSet: Contains 'Name', 'SqlInjectionMatchSetId', and
--     an array of 'SqlInjectionMatchTuple' objects
-- -   SqlInjectionMatchTuple: Each 'SqlInjectionMatchTuple' object
--     contains 'FieldToMatch' and 'TextTransformation'
-- -   FieldToMatch: Contains 'Data' and 'Type'
gsimsrsSqlInjectionMatchSet :: Lens' GetSqlInjectionMatchSetResponse (Maybe SqlInjectionMatchSet)
gsimsrsSqlInjectionMatchSet = lens _gsimsrsSqlInjectionMatchSet (\ s a -> s{_gsimsrsSqlInjectionMatchSet = a});

-- | The response status code.
gsimsrsResponseStatus :: Lens' GetSqlInjectionMatchSetResponse Int
gsimsrsResponseStatus = lens _gsimsrsResponseStatus (\ s a -> s{_gsimsrsResponseStatus = a});
