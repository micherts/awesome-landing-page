function submitToAPI(e) {
  e.preventDefault();
  // var url = "https://6gcdonb7r7.execute-api.ap-southeast-2.amazonaws.com"; // Powershell version
  var url =
    "https://w3ropshyh65eomdjyxnhn2v4wm0tfdgj.lambda-url.ap-southeast-2.on.aws/"; // Amplify staging

  var mandatory = /[A-Za-z0-9\W]/;
  if (!mandatory.test($("#form_name").val())) {
    alert("Please enter your name");
    return;
  }

  if ($("#form_email").val() == "") {
    alert("Please enter your email");
    return;
  }

  var emailRe = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,6})?$/;
  if (!emailRe.test($("#form_email").val())) {
    alert("Please enter valid email address");
    return;
  }

  // var mandatory = /[A-Za-z0-9\W]/;
  // if (!mandatory.test($("#form_referral").val())) {
  //   alert("Please advise how you found out about us?");
  //   return;
  // }

  // if (!mandatory.test($("#form_owner").val())) {
  //   alert("Please let us know if you currently own a cafe?");
  //   return;
  // }

  // if (!mandatory.test($("#form_opening").val())) {
  //   alert("Please let us know if you are planning to open a cafe?");
  //   return;
  // }

  // if (!mandatory.test($("#form_experience").val())) {
  //   alert(
  //     "Please let us know how many years experience you have in hospitality management?"
  //   );
  //   return;
  // }

  // var name = $("#form_name").val();
  // var email = $("#form_email").val();
  // var telephone = $("#form_telephone").val();
  // var referral = $("#form_referral").val();
  // var owner = $("#form_owner").val();
  // var opening = $("#form_opening").val();
  // var experience = $("#form_experience").val();
  // var financials = $("#form_financials").val();
  // var costed = $("#form_costed").val();
  // var costing = $("#form_costing").val();
  // var message = $("#form_message").val();
  var data = {
    subject: "HospoSure Contact Form",
    name: $("#form_name").val(),
    email: $("#form_email").val(),
    // telephone: $("#form_telephone").val(),
    // referral: $("#form_referral").val(),
    // owner: $("#form_owner").val(),
    // opening: $("#form_opening").val(),
    // experience: $("#form_experience").val(),
    // financials: $("#form_financials").val(),
    // costed: $("#form_costed").val(),
    // costing: $("#form_costing").val(),
    message: $("#form_message").val(),
  };

  // console.log(JSON.stringify(data));

  // send POST request
  fetch(url, {
    method: "POST",
    origin: "https://hosposure.com.au",
    body: JSON.stringify(data),
    headers: {
      "Content-Type": "application/json",
    },
  })
    .then((response) => {
      if (response.status === 200) {
        alert(
          "Thank you for your interest in HospoSure, we look forward to chatting."
        );
        document.getElementById("contact-form").reset();
      } else {
        alert(
          `Oops something broke, sorry about that, please contact us at hello@hosposure.com.au instead.`
        );
        console.log("Error: ", response);
      }
      // console.log("Response: ", response);
    })
    .catch((error) => {
      alert(`Error: ${error}`);
      console.log("Error: ", error);
    });
}
