defmodule Oli.Delivery.Certificates.CertificateRendererTest do
  use Oli.DataCase
  import Oli.Factory

  alias Oli.Delivery.Certificates.CertificateRenderer

  test "renders certificate template correctly using a granted certificate" do
    gc = insert(:granted_certificate)

    rendered_html = CertificateRenderer.render(gc)

    assert rendered_html =~ "Certificate ID: #{gc.guid}"
  end

  test "renders certificate template correctly using assigns map" do
    assigns = %{
      certificate_type: "Completion Certificate",
      student_name: "John Doe",
      completion_date: "2025-02-06",
      course_name: "Introduction to Testing",
      course_description: "Learn how to write tests in Elixir",
      administrators: [
        {"Alice Smith", "Program Administrator"},
        {"Bob Johnson", "Course Administrator"}
      ],
      logos: [
        "data:image/gif;base64,R0lGODlhAQABAAAAACw=",
        "data:image/gif;base64,R0lGODlhAQABAAAAACw="
      ],
      certificate_id: "CERT123456",
      certificate_verification_url: "some_url"
    }

    rendered_html = CertificateRenderer.render(assigns)

    assert rendered_html =~ "Completion Certificate"
    assert rendered_html =~ "John Doe"
    assert rendered_html =~ "Introduction to Testing"
    assert rendered_html =~ "Learn how to write tests in Elixir"
    assert rendered_html =~ "2025-02-06"
    assert rendered_html =~ "Alice Smith"
    assert rendered_html =~ "Program Administrator"
    assert rendered_html =~ "Bob Johnson"
    assert rendered_html =~ "Course Administrator"
    assert rendered_html =~ "<img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACw=\""
    assert rendered_html =~ "Certificate ID: CERT123456"
  end
end
