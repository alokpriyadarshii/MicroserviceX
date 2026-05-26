package org.springframework.samples.animalclinic.visits.config;

import io.micrometer.core.aop.TimedAspect;
import io.micrometer.core.instrument.MeterRegistry;
import org.jspecify.annotations.NonNull;
import org.springframework.boot.micrometer.metrics.autoconfigure.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MetricConfig {

  @Bean
  MeterRegistryCustomizer<@NonNull MeterRegistry> metricsCommonTags() {
    return registry -> registry.config().commonTags("application", "animalclinic");
  }

  @Bean
  TimedAspect timedAspect(MeterRegistry registry) {
    return new TimedAspect(registry);
  }

}
