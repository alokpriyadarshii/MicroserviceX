package org.springframework.samples.animalclinic.customers.web.mapper;

public interface Mapper<R, E> {
    E map(E response, R request);
}
