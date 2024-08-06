// Generated automatically from software.amazon.awssdk.services.s3.model.ListBucketInventoryConfigurationsRequest for testing purposes

package software.amazon.awssdk.services.s3.model;

import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;
import software.amazon.awssdk.awscore.AwsRequestOverrideConfiguration;
import software.amazon.awssdk.core.SdkField;
import software.amazon.awssdk.core.SdkPojo;
import software.amazon.awssdk.services.s3.model.S3Request;
import software.amazon.awssdk.utils.builder.CopyableBuilder;
import software.amazon.awssdk.utils.builder.ToCopyableBuilder;

public class ListBucketInventoryConfigurationsRequest extends S3Request implements ToCopyableBuilder<ListBucketInventoryConfigurationsRequest.Builder, ListBucketInventoryConfigurationsRequest>
{
    protected ListBucketInventoryConfigurationsRequest() {}
    public ListBucketInventoryConfigurationsRequest.Builder toBuilder(){ return null; }
    public final <T> java.util.Optional<T> getValueForField(String p0, java.lang.Class<T> p1){ return null; }
    public final List<SdkField<? extends Object>> sdkFields(){ return null; }
    public final String bucket(){ return null; }
    public final String continuationToken(){ return null; }
    public final String expectedBucketOwner(){ return null; }
    public final String toString(){ return null; }
    public final boolean equals(Object p0){ return false; }
    public final boolean equalsBySdkFields(Object p0){ return false; }
    public final int hashCode(){ return 0; }
    public static ListBucketInventoryConfigurationsRequest.Builder builder(){ return null; }
    public static java.lang.Class<? extends ListBucketInventoryConfigurationsRequest.Builder> serializableBuilderClass(){ return null; }
    static public interface Builder extends CopyableBuilder<ListBucketInventoryConfigurationsRequest.Builder, ListBucketInventoryConfigurationsRequest>, S3Request.Builder, SdkPojo
    {
        ListBucketInventoryConfigurationsRequest.Builder bucket(String p0);
        ListBucketInventoryConfigurationsRequest.Builder continuationToken(String p0);
        ListBucketInventoryConfigurationsRequest.Builder expectedBucketOwner(String p0);
        ListBucketInventoryConfigurationsRequest.Builder overrideConfiguration(AwsRequestOverrideConfiguration p0);
        ListBucketInventoryConfigurationsRequest.Builder overrideConfiguration(java.util.function.Consumer<AwsRequestOverrideConfiguration.Builder> p0);
    }
}
