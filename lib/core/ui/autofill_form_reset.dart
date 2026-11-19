import 'package:flutter/services.dart';

/// Removes the hidden autofill forms left in the page, without saving.
///
/// Web: when a password field loses focus (unfocus on submit, click on the eye
/// icon), Flutter keeps a hidden copy of the fields in the DOM (dormant
/// autofill form). Chrome then keeps pushing the old password back into the
/// field, which can no longer be edited. Call it when a submit fails and before
/// toggling the password visibility. No save: nothing was accepted.
void resetAutofillForm() => TextInput.finishAutofillContext(shouldSave: false);
