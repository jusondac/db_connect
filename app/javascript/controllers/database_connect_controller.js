import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlHidden", "urlDisplay", "host", "port", "databaseName"]

  connect() {
    this.updateUrl()
  }

  updateUrl() {
    const host = this.hostTarget.value || ""
    const port = this.portTarget.value || ""
    const databaseName = this.databaseNameTarget.value || ""

    const url = `jdbc:postgresql://${host}:${port}/${databaseName}`
    this.urlHiddenTarget.value = url
    this.urlDisplayTarget.value = url
  }
}
