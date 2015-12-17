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
-- Module      : Network.AWS.Inspector.CreateApplication
-- Copyright   : (c) 2013-2015 Brendan Hay
-- License     : Mozilla Public License, v. 2.0.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : auto-generated
-- Portability : non-portable (GHC extensions)
--
-- Creates a new application using the resource group ARN generated by
-- CreateResourceGroup. You can create up to 50 applications per AWS
-- account. You can run up to 500 concurrent agents per AWS account. For
-- more information, see
-- <https://docs.aws.amazon.com/inspector/latest/userguide//inspector_applications.html Inspector Applications.>
--
-- /See:/ <http://docs.aws.amazon.com/inspector/latest/APIReference/API_CreateApplication.html AWS API Reference> for CreateApplication.
module Network.AWS.Inspector.CreateApplication
    (
    -- * Creating a Request
      createApplication
    , CreateApplication
    -- * Request Lenses
    , caResourceGroupARN
    , caApplicationName

    -- * Destructuring the Response
    , createApplicationResponse
    , CreateApplicationResponse
    -- * Response Lenses
    , carsApplicationARN
    , carsResponseStatus
    ) where

import           Network.AWS.Inspector.Types
import           Network.AWS.Inspector.Types.Product
import           Network.AWS.Lens
import           Network.AWS.Prelude
import           Network.AWS.Request
import           Network.AWS.Response

-- | /See:/ 'createApplication' smart constructor.
data CreateApplication = CreateApplication'
    { _caResourceGroupARN :: !(Maybe Text)
    , _caApplicationName  :: !(Maybe Text)
    } deriving (Eq,Read,Show,Data,Typeable,Generic)

-- | Creates a value of 'CreateApplication' with the minimum fields required to make a request.
--
-- Use one of the following lenses to modify other fields as desired:
--
-- * 'caResourceGroupARN'
--
-- * 'caApplicationName'
createApplication
    :: CreateApplication
createApplication =
    CreateApplication'
    { _caResourceGroupARN = Nothing
    , _caApplicationName = Nothing
    }

-- | The ARN specifying the resource group that is used to create the
-- application.
caResourceGroupARN :: Lens' CreateApplication (Maybe Text)
caResourceGroupARN = lens _caResourceGroupARN (\ s a -> s{_caResourceGroupARN = a});

-- | The user-defined name identifying the application that you want to
-- create. The name must be unique within the AWS account.
caApplicationName :: Lens' CreateApplication (Maybe Text)
caApplicationName = lens _caApplicationName (\ s a -> s{_caApplicationName = a});

instance AWSRequest CreateApplication where
        type Rs CreateApplication = CreateApplicationResponse
        request = postJSON inspector
        response
          = receiveJSON
              (\ s h x ->
                 CreateApplicationResponse' <$>
                   (x .?> "applicationArn") <*> (pure (fromEnum s)))

instance ToHeaders CreateApplication where
        toHeaders
          = const
              (mconcat
                 ["X-Amz-Target" =#
                    ("InspectorService.CreateApplication" :: ByteString),
                  "Content-Type" =#
                    ("application/x-amz-json-1.1" :: ByteString)])

instance ToJSON CreateApplication where
        toJSON CreateApplication'{..}
          = object
              (catMaybes
                 [("resourceGroupArn" .=) <$> _caResourceGroupARN,
                  ("applicationName" .=) <$> _caApplicationName])

instance ToPath CreateApplication where
        toPath = const "/"

instance ToQuery CreateApplication where
        toQuery = const mempty

-- | /See:/ 'createApplicationResponse' smart constructor.
data CreateApplicationResponse = CreateApplicationResponse'
    { _carsApplicationARN :: !(Maybe Text)
    , _carsResponseStatus :: !Int
    } deriving (Eq,Read,Show,Data,Typeable,Generic)

-- | Creates a value of 'CreateApplicationResponse' with the minimum fields required to make a request.
--
-- Use one of the following lenses to modify other fields as desired:
--
-- * 'carsApplicationARN'
--
-- * 'carsResponseStatus'
createApplicationResponse
    :: Int -- ^ 'carsResponseStatus'
    -> CreateApplicationResponse
createApplicationResponse pResponseStatus_ =
    CreateApplicationResponse'
    { _carsApplicationARN = Nothing
    , _carsResponseStatus = pResponseStatus_
    }

-- | The ARN specifying the application that is created.
carsApplicationARN :: Lens' CreateApplicationResponse (Maybe Text)
carsApplicationARN = lens _carsApplicationARN (\ s a -> s{_carsApplicationARN = a});

-- | The response status code.
carsResponseStatus :: Lens' CreateApplicationResponse Int
carsResponseStatus = lens _carsResponseStatus (\ s a -> s{_carsResponseStatus = a});
