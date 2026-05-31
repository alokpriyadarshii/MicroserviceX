package org.springframework.samples.animalclinic.customers.web;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.samples.animalclinic.customers.model.Owner;
import org.springframework.samples.animalclinic.customers.model.OwnerRepository;
import org.springframework.samples.animalclinic.customers.model.Pet;
import org.springframework.samples.animalclinic.customers.model.PetRepository;
import org.springframework.samples.animalclinic.customers.model.PetType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;


import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * @author Maciej Szarlinski
 */
@WebMvcTest(PetResource.class)
@ActiveProfiles("test")
class PetResourceTest {

    @Autowired
    MockMvc mvc;

    @MockitoBean
    PetRepository petRepository;

    @MockitoBean
    OwnerRepository ownerRepository;

    @Test
    void shouldGetAPetInJSonFormat() throws Exception {

        Pet pet = setupPet();

        given(petRepository.findById(2)).willReturn(Optional.of(pet));


        mvc.perform(get("/owners/2/pets/2").accept(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(content().contentType("application/json"))
            .andExpect(jsonPath("$.id").value(2))
            .andExpect(jsonPath("$.name").value("Basil"))
            .andExpect(jsonPath("$.type.id").value(6));
    }

    @Test
    void shouldUsePathPetIdWhenUpdatingPet() throws Exception {
        Pet pet = setupPet();
        PetType petType = new PetType();
        petType.setId(7);

        given(petRepository.findById(2)).willReturn(Optional.of(pet));
        given(petRepository.findPetTypeById(7)).willReturn(Optional.of(petType));

        mvc.perform(put("/owners/2/pets/2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "id": 999,
                      "name": "Basil Updated",
                      "birthDate": "2024-01-15",
                      "typeId": 7
                    }
                    """))
            .andExpect(status().isNoContent());

        verify(petRepository).findById(2);
        verify(petRepository, never()).findById(999);
        verify(petRepository).save(pet);
    }

    @Test
    void shouldRejectInvalidPetWhenCreatingPet() throws Exception {
        mvc.perform(post("/owners/2/pets")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "id": 0,
                      "name": "",
                      "birthDate": "2024-01-15",
                      "typeId": 7
                    }
                    """))
            .andExpect(status().isBadRequest());

        verify(petRepository, never()).save(org.mockito.ArgumentMatchers.any(Pet.class));
    }

    @Test
    void shouldRejectUnknownPetTypeWhenUpdatingPet() throws Exception {
        Pet pet = setupPet();

        given(petRepository.findById(2)).willReturn(Optional.of(pet));
        given(petRepository.findPetTypeById(99)).willReturn(Optional.empty());

        mvc.perform(put("/owners/2/pets/2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "id": 2,
                      "name": "Basil Updated",
                      "birthDate": "2024-01-15",
                      "typeId": 99
                    }
                    """))
            .andExpect(status().isNotFound());

        verify(petRepository, never()).save(pet);
    }

    private Pet setupPet() {
        Owner owner = new Owner();
        owner.setFirstName("George");
        owner.setLastName("Bush");

        Pet pet = new Pet();

        pet.setName("Basil");
        pet.setId(2);

        PetType petType = new PetType();
        petType.setId(6);
        pet.setType(petType);

        owner.addPet(pet);
        return pet;
    }
}
