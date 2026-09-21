// Create or update cleanup policies through the published Script API.
// This Community Edition has no public /service/rest/v1/cleanup-policies.
// Criteria values in the JSON args are days; storage keeps seconds.
import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import java.util.concurrent.TimeUnit
import org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage

def storage = container.lookup(CleanupPolicyStorage.class.getName()) as CleanupPolicyStorage
def parsed = new JsonSlurper().parseText(args)
if (!(parsed instanceof List)) {
  parsed = [parsed]
}

def daysToSeconds(value) {
  return String.valueOf(TimeUnit.DAYS.toSeconds((value as Number).longValue()))
}

def results = []
parsed.each { item ->
  try {
    Map<String, String> criteria = [:]
    if (item.criteriaLastDownloaded != null && "${item.criteriaLastDownloaded}" != '') {
      criteria.put('lastDownloaded', daysToSeconds(item.criteriaLastDownloaded))
    }
    if (item.criteriaLastBlobUpdated != null && "${item.criteriaLastBlobUpdated}" != '') {
      criteria.put('lastBlobUpdated', daysToSeconds(item.criteriaLastBlobUpdated))
    }
    def format = (item.format == 'all') ? 'ALL_FORMATS' : item.format
    if (storage.exists(item.name)) {
      def policy = storage.get(item.name)
      policy.setNotes(item.notes ?: '')
      policy.setFormat(format)
      policy.setCriteria(criteria)
      storage.update(policy)
      results << [name: item.name, status: 'updated']
    } else {
      def policy = storage.newCleanupPolicy()
      policy.setName(item.name)
      policy.setNotes(item.notes ?: '')
      policy.setFormat(format)
      policy.setMode('deletion')
      policy.setCriteria(criteria)
      storage.add(policy)
      results << [name: item.name, status: 'created']
    }
  } catch (Exception e) {
    results << [name: item.name, status: 'error', error: e.toString()]
  }
}
return JsonOutput.toJson(results)
