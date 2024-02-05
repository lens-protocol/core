/*
    List of tests for PermissionlessCreator contract:

    // Paid creation

        // Negatives

            // Payment negatives
            testCannot_CreateProfile_IfNotEnoughPayment
            testCannot_CreateHandle_IfNotEnoughPayment
            testCannot_CreateProfileWithHandle_IfNotEnoughPayment

            // DelegatedExecutors negatives
            testCannot_CreateProfile_WithDE_IfNotToHimself
            testCannot_CreateHandle_WithDE_IfNotToHimself
            testCannot_CreateProfileWithHandle_WithDE_IfNotToHimself

            // Handle Length negatives
            testCannot_CreateHandle_IfHandleLengthIsLessThanMin
            testCannot_CreateProfileWithHandle_IfHandleLengthIsLessThanMin

        // Scenarios

        testCreateProfile_WithDE
        testCreateProfile_WithoutDE
        testCreateHandle
        testCreateProfileWithHandle_WithDE
        testCreateProfileWithHandle_WithoutDE

    // Creation with credits

        // Negatives

            // Credits negatives
            testCannot_CreateProfileUsingCredits_IfNotEnoughCredits
            testCannot_CreateHandleUsingCredits_IfNotEnoughCredits
            testCannot_CreateProfileWithHandleUsingCredits_IfNotEnoughCredits

            // TrustRevoked negatives
            testCannot_CreateProfileUsingCredits_IfTrustRevoked
            testCannot_CreateHandleUsingCredits_IfTrustRevoked
            testCannot_CreateProfileWithHandleUsingCredits_IfTrustRevoked

            // Handle Length negatives
            testCannot_CreateHandleUsingCredits_IfHandleLengthIsLessThanMin
            testCannot_CreateProfileWithHandleUsingCredits_IfHandleLengthIsLessThanMin

        // Scenarios

        testCreateProfileUsingCredits
        testCreateHandleUsingCredits
        testCreateProfileWithHandleUsingCredits

    // TransferFromKeepingDelegates helper function

        // Negatives

        testCannot_TransferFromKeepingDelegates_IfTrustRevoked
        testCannot_TransferFromKeepingDelegates_IfWasNotCreator

        // Scenarios

        testTransferFromKeepingDelegates

    // Credit Provider functions

        // Negatives

        testCannot_IncreaseCredit_IfNotCreditProvider
        testCannot_DecreaseCredit_IfNotCreditProvider
        testCannot_IncreaseCredit_IfTrustRevoked

        // Scenarios

        testIncreaseCredit
        testDecreaseCredit

    // Owner functions

        // Negatives

        testCannot_WithdrawCredits_IfNotOwner
        testCannot_AddCreditProvider_IfNotOwner
        testCannot_RemoveCreditProvider_IfNotOwner
        testCannot_SetProfileCreationPrice_IfNotOwner
        testCannot_SetHandleCreationPrice_IfNotOwner
        testCannot_SetHandleLengthMin_IfNotOwner
        testCannot_SetTrustRevoked_IfNotOwner

        // Scenarios

        testWithdrawCredits
        testAddCreditProvider
        testRemoveCreditProvider
        testSetProfileCreationPrice
        testSetHandleCreationPrice
        testSetHandleLengthMin
        testSetTrustRevoked

    // Getters

        testGetProfileWithHandleCreationPrice
        testGetProfileCreationPrice
        testGetHandleCreationPrice
        testGetHandleLengthMin
        testIsTrustRevoked
        testIsCreditProvider
        testGetCreditBalance

*/
